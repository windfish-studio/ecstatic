defmodule SystemTest do
  use ExUnit.Case, async: false
  alias Test.TestingComponent.{OneComponent, AnotherOneComponent}
  alias Test.TestingSystem.{OneSystem, ReactiveSystem,
                            RealTimeSystem, OneSecFiveShotsSystem, DualSystem, DefaultSystem}
  alias Ecstatic.{Entity, Changes, Component, Store, Aspect}
  @moduletag :capture_log

  doctest OneSystem #this is a system

  setup context do
    {entity_id, components, _pids} = TestHelper.initialize(context[:systems])
    [entity_id: entity_id, components: components]
  end

  def assert_tick_0(system_module, time_out \\ 50) when is_number(time_out) do
    assert_receive {system_module, {_entity, %{updated: [
                                             {%{state: %{var: 0, f: 0}},
                                               %{state: %{var: 1, f: :infinity}} }
                                                            ] }}}, time_out
  end

  def periodic_assertions_reception(system_module, range, time_out, expected_f \\ :ignore) do
    Enum.each(range, fn n ->
      old = n-1
      {_, {_, changes}} = assert_receive {system_module, {_entity, %{updated: [
                                                                       {%{state: %{var: ^old}},
                                                                         %{state: %{var: ^n}} }] }}}, time_out
      [{_,%Component{state: %{f: f}}}] = changes.updated
      case expected_f do
        :ignore -> assert true
        _ -> assert_in_delta(f, expected_f, expected_f/100)
      end

    end)
  end

  describe "basic structure" do
    
    @tag systems: [OneSystem]
    test "check changes structure", context do
      {entity_id, _components} = {context.entity_id, context.components}
      #tick 0
      assert_receive {OneSystem,
                       {%Entity{id: ^entity_id}, %Changes{updated: [
                                                     {%{state: %{var: 0, f: 0}},
                                                       %{state: %{var: 1, f: :infinity}} }] }}}, 500
      #tick 1
      {_, {_, changes}} = assert_receive {OneSystem,
                                 {%Entity{id: ^entity_id}, %Changes{updated: [
                                                               {%{state: %{var: 1, f: :infinity}},
                                                                 %{state: %{var: 2}} }] }}}, 1050
      [{_,%Component{state: %{f: f}}}] = changes.updated
       assert_in_delta(f, 1, 0.01)
    end

    
    test "new timer aspect" do
      aspect = Aspect.new([OneComponent], [AnotherOneComponent], [every: 1000, for: :infinity])
      assert aspect == %Aspect{with: [OneComponent],
                                without: [AnotherOneComponent],
                                trigger_condition: [every: 1000, for: :infinity]}
    end

    
    test "new conditional aspect" do
      aspect = Aspect.new([OneComponent, AnotherComponent],
                          [],
                          [fun: fn (_entity,_changes) -> true end,
                          lifecycle: :updated])
      %Aspect{with: with, without: without, trigger_condition: [fun: fun, lifecycle: lifecycle]} = aspect
      assert with == [OneComponent, AnotherComponent]
      assert without == []
      assert is_function(fun)
      assert lifecycle == :updated
      #TODO: define for this aspect lifecycle
    end
  end

  describe "non-reactive var" do
    
    @tag systems: [OneSystem]
    test "1 tick per second system" do
      assert_tick_0(OneSystem)
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 1050
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 1050
    end

    
    @tag systems: [OneSystem]
    test "ticks exactly per 1 sec" do
      assert_tick_0(OneSystem)
      refute_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 950
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 1050
      refute_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 950
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 1050
    end

    
    @tag systems: [OneSecFiveShotsSystem]
    test "limited ticks with helper" do
      assert_tick_0(OneSecFiveShotsSystem)
      periodic_assertions_reception(OneSecFiveShotsSystem, 2..5, 1050)
    end

    
    @tag systems: [DefaultSystem]
    test "just one reception" do
      assert_tick_0(DefaultSystem)
      refute_receive {DefaultSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 2500
    end

    
    @tag systems: [RealTimeSystem]
    test "real time execution" do
      periodic_assertions_reception(RealTimeSystem, 1..10, 50)
    end

    
    @tag systems: [DualSystem]
    test "2 components 1 system" do
      {Test.TestingSystem.OneSystem, {%Ecstatic.Entity{components: [%Ecstatic.Component
        {id: "09e184d7-83d7-4dfd-a31b-678796ee1698", state: %{f: 0, var: 0}, type: Test.TestingComponent.OneComponent},
                                                         %Ecstatic.Component{id: "eaf9fb50-3191-47db-8fc7-45ada73c9c57",
                                                           state: %{another_var: :zero, var: 0},
                                                           type: Test.TestingComponent.AnotherOneComponent}],
        id: "35ff8e4a-09bb-497a-aab4-b0b49b4b228f"},
        %Ecstatic.Changes{attached: [], removed: [], updated: [
                                                       {%Ecstatic.Component{id: "09e184d7-83d7-4dfd-a31b-678796ee1698",
                                                         state: %{f: 0, var: 0}, type: Test.TestingComponent.OneComponent},
                                                         %Ecstatic.Component{id: "09e184d7-83d7-4dfd-a31b-678796ee1698",
                                                           state: %{f: :infinity, var: 1},
                                                           type: Test.TestingComponent.OneComponent}}]}}}

      assert_receive {DualSystem, {_entity, %{updated:
                                              [ {%{state: %{var: 0}}, %{state: %{var: 1}} },
                                                {%{state: %{var: 0}}, %{state: %{var: -1}} }
                                            ] }}}, 50
    end

    @tag systems: [OneSystem, DefaultSystem]
    test "2 systems 1 component. Each system only triggers itself" do
      #DefaultSystem is triggering OneSystem after 1 sec
      assert_tick_0(OneSystem)
      assert_receive {DefaultSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 50
      refute_receive {_system, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 850
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 200
      refute_receive {_system, {_entity, %{updated: [ {%{state: %{var: 3}}, %{state: %{var: 4}} }] }}}, 850
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 3}}, %{state: %{var: 4}} }] }}}, 200
    end
  end

  describe "delta on non-reactive systems" do


    def assert_graphically_fluid(range, time_out, expected_f \\ 120) do
      Enum.each(range, fn n ->
        old = n-1
        {_, {_, changes}} = assert_receive {RealTimeSystem, {_entity, %{updated: [
                                                                           {%{state: %{var: ^old}},
                                                                             %{state: %{var: ^n}} }] }}}, time_out
        [{_,%Component{state: %{f: f}}}] = changes.updated
        assert f>expected_f
      end)
    end

    
    @tag systems: [OneSecFiveShotsSystem]
    test "5 ticks in 5 seconds, frec » 1Hz" do
      assert_tick_0(OneSecFiveShotsSystem)
      periodic_assertions_reception(OneSecFiveShotsSystem, 2..5, 1050, 1)
      refute_receive {OneSecFiveShotsSystem, _}, 50
    end

    
    @tag systems: [RealTimeSystem]
    test "real time execution" do
      assert_tick_0(RealTimeSystem)
      assert_graphically_fluid(2..10, 50)
    end
  end

  describe "reactive" do
    
    @tag systems: [ReactiveSystem]
    test "0 changes", context do
      c = Map.get(context, :components)
          |> Enum.at(0)
      assert c.state.var == 0
      refute_receive {OneSystem, _}, 2000
    end



    @tag systems: [OneSystem, ReactiveSystem]
    test "Reactive that triggers itself", context do
       entity_id = context.entity_id
       assert_tick_0(ReactiveSystem) #OnSecInfinity triggers Reactive who endlessly triggers itself
       assert_receive {ReactiveSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 11}} }] }}}, 50
       refute_receive {ReactiveSystem, {_entity, %{updated: [ {%{state: %{var: 11}}, %{state: %{var: 21}} }] }}}, 2000
       c = Store.Ets.get_entity(entity_id)
           |> Entity.find_component(OneComponent)
       assert c.state.var == 11
    end

    @tag systems: [OneSystem, ReactiveSystem]
    test "Non reactive should trigger reactive", context do
      entity_id = context.entity_id
      assert_tick_0(OneSystem)
      #Reactive is triggered by the change, but the gotten value is the old one
      assert_receive {ReactiveSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 11}} }] }}}, 50
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 11}}, %{state: %{var: 12}} }] }}}, 1050
      assert_receive {ReactiveSystem, {_entity, %{updated: [ {%{state: %{var: 12}}, %{state: %{var: 22}} }] }}}, 50
      c = Store.Ets.get_entity(entity_id)
          |> Entity.find_component(OneComponent)
      assert c.state.var == 22
    end
  end
end
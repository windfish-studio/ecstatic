defmodule SystemTest do
  use ExUnit.Case, async: false
  alias Test.TestingComponent.{OneComponent, AnotherOneComponent}
  alias Test.TestingSystem.{OneSystem, NullSystem,
                            RealTimeSystem, OneSecFiveShotsSystem, DualSystem, DefaultSystem}
  alias Test.TestingSystem.Reactive.{ToUpdatedSystem, ToSelfSystem, ToSelfLimitedSystem, ToAttachSystem,
    ToOtherSystem}
  alias Ecstatic.{Entity, Changes, Component, Store, Aspect}
  @moduletag :capture_log

  doctest OneSystem #this is a system

  setup context do
    {entity_id, components, _pids} = TestHelper.initialize(context[:systems])
    [entity_id: entity_id, components: components]
  end

  def assert_tick_0(system_module, time_out \\ 50) when is_number(time_out) do
    assert_receive {^system_module, {_entity, %{updated: [
                                             {%{state: %{var: 0, f: 0}},
                                               %{state: %{var: 1, f: :infinity}} }
                                                            ] }}}, time_out
  end

  def assert_received_0(system_module) do
    assert_received {^system_module, {_entity, %{updated: [
                                                {%{state: %{var: 0, f: 0}},
                                                  %{state: %{var: 1, f: :infinity}} }
    ] }}}



  end

  def periodic_assertions_reception(system_module, range, time_out, expected_f \\ :ignore) do
    Enum.each(range, fn n ->
      old = n-1
      {_, {_, changes}} = assert_receive {^system_module, {_entity, %{updated: [
                                                                       {%{state: %{var: ^old}},
                                                                         %{state: %{var: ^n}} }] }}}, time_out
      [{_,%Component{state: %{f: f}}}] = changes.updated
      case expected_f do
        :ignore -> assert true
        _ -> assert_in_delta(f, expected_f, expected_f/100)
      end

    end)
  end

  def periodic_received(system_module, range) do
    Enum.each(range, fn n ->
      old = n-1
      {_, {_, _changes}} = assert_received {^system_module, {_entity, %{updated: [
                                                                        {%{state: %{var: ^old}},
                                                                          %{state: %{var: ^n}} }] }}}
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
      aspect = Aspect.new([OneComponent, AnotherOneComponent],
                          [],
                          [condition: fn (_system, _entity,_changes) -> true end,
                          lifecycle: [:updated]])
      %Aspect{with: with, without: without, trigger_condition: [condition: fun, lifecycle: lifecycle]} = aspect
      assert with == [OneComponent, AnotherOneComponent]
      assert without == []
      assert is_function(fun)
      assert lifecycle == [:updated]
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
       {DualSystem, {entity, _}} = assert_receive {DualSystem, {_entity, %{updated:
                                [ {%{state: %{var: 0}}, %{state: %{var: 1}} },
                                  {%{state: %{var: 0}}, %{state: %{var: -1}} }
                              ] }}}, 50
       TestHelper.wait_receiver(100)
      e = Store.Ets.get_entity(entity.id)
      c1 = Entity.find_component(e, OneComponent)
      c2 = Entity.find_component(e, AnotherOneComponent)
      assert c1.state.var == 1
      assert c2.state.var == -1
    end

    
    @tag systems: [NullSystem]
    test "0 ticks left" do
      refute_receive {NullSystem, _}, 200
    end

    
    @tag systems: [OneSystem, DefaultSystem]
    test "2 systems 1 component. Each system only triggers itself. Default triggers only once" do
      assert_receive {_system, {_entity, %{updated: [ {%{state: %{var: 0}}, %{state: %{var: 1}} }] }}}, 50
      assert_receive {_system, {_entity, %{updated: [ {%{state: %{var: 0}}, %{state: %{var: 1}} }] }}}, 50
      refute_receive {_system, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 850
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 200
      refute_receive {_system, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 850
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 200
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
    
    @tag systems: [ToUpdatedSystem]
    test "0 changes", context do
      refute_receive {ToUpdatedSystem, _}, 2000
      c = Map.get(context, :components)
          |> Enum.at(0)
      assert c.state.var == 0
    end

    
    @tag systems: [ToSelfSystem]
    test "Reactive that triggers itself" do
      TestHelper.wait_receiver(100)
      periodic_received(ToSelfSystem, 1..10)
    end
    
    @tag systems: [ToSelfLimitedSystem]
    test "Reactive to self while var minor 10" do
      TestHelper.wait_receiver(200)
      periodic_received(ToSelfLimitedSystem, 1..10)
      refute_received({ToSelfLimitedSystem, {_entity, %{updated: [
                                                     {%{state: %{var: 10}},
                                                       %{state: %{var: 11}} }] }}})
    end
    
    @tag systems: [ToAttachSystem, ToOtherSystem]
    test "A system triggers another system" do
      TestHelper.wait_receiver(200)
      periodic_received(ToAttachSystem, 1..1)
      refute_received({ToAttachSystem, _})
      periodic_received(ToOtherSystem, 2..2)
    end
  end

  describe "reactive and non reactive" do
    
    @tag systems: [OneSystem, ToUpdatedSystem]
    test "Non reactive should trigger reactive", context do
      entity_id = context.entity_id
      assert_tick_0(OneSystem)
      assert_receive {ToUpdatedSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 11}} }] }}}, 50
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 11}}, %{state: %{var: 12}} }] }}}, 1050
      assert_receive {ToUpdatedSystem, {_entity, %{updated: [ {%{state: %{var: 12}}, %{state: %{var: 22}} }] }}}, 50
      TestHelper.wait_receiver(100)
      c = Store.Ets.get_entity(entity_id)
          |> Entity.find_component(OneComponent)
      assert c.state.var == 22
    end
  end

  #TODO: a system that makes changes to another entity. For instance, Entity TANK destroys Entity HOME
end
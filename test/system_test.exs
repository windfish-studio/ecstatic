defmodule SystemTest do
  use ExUnit.Case, async: false
  alias Test.TestingComponent.OneComponent
  alias Test.TestingSystem.{OneSystem, AnotherOneSystem, ReactiveSystem}
  alias Ecstatic.{Entity, Changes, Component, Store}
  alias Test.TestingWatcher.Reactive.{Reactive}
  alias Test.TestingWatcher.NonReactive.{OneSecInfinity, OneSecFiveShots, OneShot, RealTime, Couple}
  @moduletag :capture_log

  doctest OneSystem #this is a system

  setup context do
    {entity_id, components, _pids} = TestHelper.initialize(context[:watchers])
    [entity_id: entity_id, components: components]
  end

  def assert_tick_0(time_out \\ 50) do
    assert_receive {OneSystem, {_entity, %{updated: [
                                                     {%{state: %{var: 0, f: 0}},
                                                      %{state: %{var: 1, f: :infinity}} }
                                                            ] }}}, time_out
  end

  describe "basic structure" do
    @tag watchers: [OneSecInfinity]
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
  end

  describe "non-reactive var" do
    def periodic_assertions_reception(range, time_out) do
      Enum.each(range, fn n ->
        old = n-1
        assert_receive {OneSystem, {_entity, %{updated: [
                                             {%{state: %{var: ^old}},
                                               %{state: %{var: ^n}} }] }}}, time_out
      end)
    end

    @tag watchers: [OneSecInfinity]
    test "1 tick per second system" do
      assert_tick_0()
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 1050
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 1050
    end

    @tag watchers: [OneSecInfinity]
    test "ticks exactly per 1 sec" do
      assert_tick_0()
      refute_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 950
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 1050
      refute_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 950
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 1050
    end

    @tag watchers: [OneSecFiveShots]
    test "limited ticks with helper" do
      assert_tick_0()
      periodic_assertions_reception(2..5, 1050)
    end

    #TODO. Test multiple watchers over the same component
    @tag watchers: [OneShot]
    test "just one reception" do
      assert_tick_0()
      refute_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 2500
    end

    @tag watchers: [RealTime]
    test "real time execution" do
      periodic_assertions_reception(1..10, 50)
    end

    @tag watchers: [Couple]
    test "a non-single watcher" do
      assert_tick_0()
      assert_receive {AnotherOneSystem, {_entity, %{updated: [ {%{state: %{var: 0}}, %{state: %{var: -1}} }] }}}, 50
    end
  end

  describe "delta on non-reactive watchers" do
    def periodic_assertions_reception(range, time_out, expected_f) do
      Enum.each(range, fn n ->
        old = n-1
        {_, {_, changes}} = assert_receive {OneSystem, {_entity, %{updated: [
                                                                           {%{state: %{var: ^old}},
                                                                             %{state: %{var: ^n}} }] }}}, time_out
        [{_,%Component{state: %{f: f}}}] = changes.updated
        assert_in_delta(f, expected_f, expected_f/100)
      end)
    end

    def assert_graphically_fluid(range, time_out, expected_f \\ 120) do
      Enum.each(range, fn n ->
        old = n-1
        {_, {_, changes}} = assert_receive {OneSystem, {_entity, %{updated: [
                                                                           {%{state: %{var: ^old}},
                                                                             %{state: %{var: ^n}} }] }}}, time_out
        [{_,%Component{state: %{f: f}}}] = changes.updated
        assert f>expected_f
      end)
    end

    @tag watchers: [OneSecFiveShots]
    test "5 ticks in 5 seconds, frec » 1Hz" do
      assert_tick_0()
      periodic_assertions_reception(2..5, 1050, 1)
      refute_receive {OneSystem, _}, 50
    end

    @tag watchers: [RealTime]
    test "real time execution" do
      assert_tick_0()
      assert_graphically_fluid(2..10, 50)
    end
  end

  describe "reactive" do
    @tag watchers: [Reactive]
    test "0 changes", context do
      c = Map.get(context, :components)
          |> Enum.at(0)
      assert c.state.var == 0
      refute_receive {OneSystem, _}, 2000
    end

    @tag watchers: [OneSecInfinity, Reactive]
    test "Non reactive should trigger reactive", context do
      entity_id = context.entity_id
      assert_tick_0()
      assert_receive {OneSystem, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 1050
      assert_receive {ReactiveSystem, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 12}} }] }}}, 1050
      c = Store.Ets.get_entity(entity_id)
          |> Entity.find_component(OneComponent)
      assert c.state.var == 12
    end

    @tag watchers: [Reactive]
    test "push reaction", _context do

    end
  end
end

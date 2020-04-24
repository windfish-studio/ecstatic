defmodule SystemTest do
  use ExUnit.Case, async: false
  alias Test.{AnotherTestingSystem, TestingSystem}
  alias Test.TestingWatcher.{OneSecInfinity}
  alias Ecstatic.{Entity, Changes, Component}
  alias Test.TestingWatcher.{OneSecInfinity, OneSecFiveShots, OneShot, RealTime, Couple}

  @moduletag :capture_log

  doctest TestingSystem

  setup context do
    {entity_id, components, _pids} = TestHelper.initialize(context[:watchers])
    [entity_id: entity_id, components: components]
  end

  describe "basic structure" do
    @tag watchers: [OneSecInfinity]
    test "check changes structure", context do
      {entity_id, _components} = {context.entity_id, context.components}
      #tick 0
      assert_receive {:testing_system,
                       {%Entity{id: ^entity_id}, %Changes{updated: [
                                                     {%{state: %{var: 0, f: 0}},
                                                       %{state: %{var: 1, f: :infinity}} }] }}}, 500
      #tick 1
      {_, {_, changes}} = assert_receive {:testing_system,
                                 {%Entity{id: ^entity_id}, %Changes{updated: [
                                                               {%{state: %{var: 1, f: :infinity}},
                                                                 %{state: %{var: 2}} }] }}}, 1050
      [{_,%Component{state: %{f: f}}}] = changes.updated
      assert_in_delta(f, 1, 0.01)
    end
  end

  describe "reactive watcher over the testing systems" do


  end

  describe "non-reactive var" do
    def periodic_assertions_reception(range, time_out) do
      Enum.each(range, fn n ->
        old = n-1
        assert_receive {:testing_system, {_entity, %{updated: [
                                             {%{state: %{var: ^old}},
                                               %{state: %{var: ^n}} }] }}}, time_out
      end)
    end

    @tag watchers: [OneSecInfinity]
    test "1 tick per second system" do
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 0}}, %{state: %{var: 1}} }] }}}, 50
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 1050
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 1050
    end

    @tag watchers: [OneSecInfinity]
    test "ticks exactly per 1 sec" do
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 0}}, %{state: %{var: 1}} }] }}}, 50
      refute_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 950
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 1050
      refute_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 950
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 2}}, %{state: %{var: 3}} }] }}}, 1050
    end

    @tag watchers: [OneSecFiveShots]
    test "limited ticks with helper" do
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 0}}, %{state: %{var: 1}} }] }}}, 50
      periodic_assertions_reception(2..5, 1050)
    end

    #TODO. Test multiple watchers over the same component
    @tag watchers: [OneShot]
    test "just one reception" do
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 0}}, %{state: %{var: 1}} }] }}}, 50
      refute_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 1}}, %{state: %{var: 2}} }] }}}, 2500
    end

    @tag watchers: [RealTime]
    test "real time execution" do
      periodic_assertions_reception(1..10, 50)
    end

    @tag watchers: [Couple]
    test "a non-single watcher" do
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 0}}, %{state: %{var: 1}} }] }}}, 50
      assert_receive {AnotherTestingSystem, {_entity, %{updated: [ {%{state: %{var: 0}}, %{state: %{var: -1}} }] }}}, 50
    end
  end

  describe "delta on non-reactive watchers" do
    def periodic_assertions_reception(range, time_out, expected_f) do
      Enum.each(range, fn n ->
        old = n-1
        {_, {_, changes}} = assert_receive {:testing_system, {_entity, %{updated: [
                                                                           {%{state: %{var: ^old}},
                                                                             %{state: %{var: ^n}} }] }}}, time_out
        [{_,%Component{state: %{f: f}}}] = changes.updated
        assert_in_delta(f, expected_f, expected_f/100)
      end)
    end

    def assert_graphically_fluid(range, time_out, expected_f \\ 120) do
      Enum.each(range, fn n ->
        old = n-1
        {_, {_, changes}} = assert_receive {:testing_system, {_entity, %{updated: [
                                                                           {%{state: %{var: ^old}},
                                                                             %{state: %{var: ^n}} }] }}}, time_out
        [{_,%Component{state: %{f: f}}}] = changes.updated
        assert f>expected_f
      end)
    end

    def assert_tick_0() do
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 0, f: 0}},
        %{state: %{var: 1, f: :infinity}} }] }}}, 50
    end

    @tag watchers: [OneSecFiveShots]
    test "5 ticks in 5 seconds, frec » 1Hz" do
      assert_receive {:testing_system, {_entity, %{updated: [ {%{state: %{var: 0, f: 0}},
        %{state: %{var: 1, f: :infinity}} }] }}}, 50
      periodic_assertions_reception(2..5, 1050, 1)
      refute_receive {:testing_system, _}, 50
    end

    @tag watchers: [RealTime]
    test "real time execution" do
      assert_tick_0()
      assert_graphically_fluid(2..10, 50)
    end
  end
end

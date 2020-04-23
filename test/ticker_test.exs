defmodule TickerTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias Test.TestingWatcher.{OneSecInfinity, OneSecFiveShots, OneShot, RealTime, Couple}
  alias Test.{TestingComponent, AnotherTestingComponent, AnotherTestingSystem}
  alias Ecstatic.{Ticker, Changes, Entity, Component}

  @moduletag :capture_log

  doctest Ticker

  setup context do
    {entity_id, components, _pids} = TestHelper.initialize(context[:watchers])
    [entity_id: entity_id, components: components]
  end
  
  def periodic_assertions_reception(range, entity_id, time_out) do
    Enum.each(range, fn n ->
                          old = n-1
    assert_receive {:testing_system,
                     {%Entity{id: ^entity_id},
                     %Changes{updated: [
                                {%Component{state: %{var: ^old, another_var: :zero}, type: TestingComponent},
                                %Component{state: %{var: ^n, another_var: :zero}, type: TestingComponent}}
                     ]}}},time_out
    end)
  end

  @tag watchers: [OneSecInfinity]
  test "1 tick per second system", context do
    {entity_id, _components} = {context.entity_id, context.components}
    assert_receive {:testing_system, {%Entity{id: ^entity_id},
                     %Changes{updated: [
                                {%Component{state: %{var: 0, another_var: :zero}, type: TestingComponent},
                                %Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}}]}}},50
    assert_receive {:testing_system, {%Entity{id: ^entity_id},
                     %Changes{updated: [{%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent},
                       %Component{state: %{var: 2, another_var: :zero}, type: TestingComponent}}]}}},1050
    assert_receive {:testing_system, {%Entity{id: ^entity_id},
                     %Changes{updated: [{%Component{state: %{var: 2, another_var: :zero}, type: TestingComponent},
                       %Component{state: %{var: 3, another_var: :zero}, type: TestingComponent}}]}}},1050
  end

  @tag watchers: [OneSecInfinity]
  test "ticks exactly per 1 sec", context do
    {entity_id, _components} = {context.entity_id, context.components}
    assert_receive {:testing_system, {%Entity{id: ^entity_id},
      %Changes{updated: [
                 {%Component{state: %{var: 0, another_var: :zero}, type: TestingComponent},
                   %Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}}]}}},50
    refute_receive {:testing_system, {%Entity{id: ^entity_id},
      %Changes{updated: [
                 {%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent},
                   %Component{state: %{var: 2, another_var: :zero}, type: TestingComponent}}]}}},950
    assert_receive {:testing_system, {%Entity{id: ^entity_id},
      %Changes{updated: [{%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent},
        %Component{state: %{var: 2, another_var: :zero}, type: TestingComponent}}]}}},1050
    refute_receive {:testing_system, {%Entity{id: ^entity_id},
      %Changes{updated: [
                 {%Component{state: %{var: 2, another_var: :zero}, type: TestingComponent},
                   %Component{state: %{var: 3, another_var: :zero}, type: TestingComponent}}]}}},950
    assert_receive {:testing_system, {%Entity{id: ^entity_id},
      %Changes{updated: [{%Component{state: %{var: 2, another_var: :zero}, type: TestingComponent},
        %Component{state: %{var: 3, another_var: :zero}, type: TestingComponent}}]}}},1050
  end

  @tag watchers: [OneSecFiveShots]
  test "limited ticks with helper", context do
    {entity_id, _components} = {context.entity_id, context.components}
    assert_receive {:testing_system,
                     {%Entity{id: ^entity_id},
                     %Changes{updated: [
                                {%Component{state: %{var: 0, another_var: :zero}, type: TestingComponent},
                                  %Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}}
                     ]}}},50
    periodic_assertions_reception(2..5, entity_id, 1050)
  end

  #TODO. Test multiple watchers over the same component
  @tag watchers: [OneShot]
  test "no more receptions", context do
    {entity_id, _components} = {context.entity_id, context.components}
    assert_receive {:testing_system,
                     {%Entity{id: ^entity_id},
                       %Changes{updated: [{
                         %Component{state: %{var: 0, another_var: :zero}, type: TestingComponent},
                          %Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}
                       }]}}},50
    refute_receive {:testing_system, {%Entity{id: ^entity_id},
      %Changes{updated: [
                 {%Component{state: %{var: 1, another_var: :zero}, type: TestingComponent},
                   %Component{state: %{var: 2, another_var: :zero}, type: TestingComponent}}]}}},2500
  end

  @tag watchers: [RealTime]
  test "real time execution", context do
    {entity_id, _components} = {context.entity_id, context.components}
    periodic_assertions_reception(1..10, entity_id, 50)
  end

  @tag watchers: [Couple]
  test "a non-single watcher", context do
   {entity_id, _components} = {context.entity_id, context.components}
   assert_receive {:testing_system,
                  {%Entity{id: ^entity_id},
                    %Changes{updated: [
                               {%Component{state: %{var: 0, another_var: :zero}, type: TestingComponent},
                               %Component{state: %{var: 1, another_var: :zero}, type: TestingComponent}}]}}},50
   assert_receive {AnotherTestingSystem,
                    {%Entity{id: ^entity_id},
                    %Changes{updated: [
                               {%Component{state: %{var: 0, another_var: :zero}, type: AnotherTestingComponent},
                               %Component{state: %{var: -1, another_var: :zero}, type: AnotherTestingComponent}}]}}},50
 end
end

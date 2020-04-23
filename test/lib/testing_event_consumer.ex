defmodule Test.TestingEventConsumer do
    @moduledoc false
    #This module is a monitor for testing. test_pid is the address of that particular test
    use GenStage
    alias Ecstatic.{Entity, Changes}
    def start_link(test_pid) do
      GenStage.start_link(__MODULE__, test_pid)
    end

    def init(test_pid) do
      {:consumer, test_pid,
        subscribe_to: [
          {
            Ecstatic.EventProducer,
            max_demand: 1,
            min_demand: 0
          }
        ]}
    end

    def handle_events([{entity, %Changes{} = changes} = _event], _from, test_pid) do
      send(test_pid, {:test_event_consumer, changes})
      {:noreply, [], test_pid}
    end
end
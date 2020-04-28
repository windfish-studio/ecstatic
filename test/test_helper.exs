ExUnit.start()
defmodule TestHelper do
  #UUID.info does the same. Replace usages by this one
  def ecs_id?(string) do
    bool = String.length(string) == 36 &&
    String.at(string,8) == "-" &&
    String.at(string,13) == "-" &&
    String.at(string,18) == "-" &&
    String.at(string,23) == "-"
    string = String.replace(string, "-", "")
    bool &&
    String.length(string) == 32 &&
    String.match?(string,~r/^[[:xdigit:][:lower:]]+$/)
  end

  def wait_receiver() do
    wait_receiver(100)
  end
  def wait_receiver(timeout_time_milisec) do
    receive do
      {:test_event_consumer, _new, _} -> wait_receiver(timeout_time_milisec)
    after
      timeout_time_milisec -> :time_out
    end
  end

  def initialize(systems \\ []) do
    {:ok, pids} = start_supervisor_with_monitor([systems: systems])
    components = [Test.TestingComponent.OneComponent.new(), Test.TestingComponent.AnotherOneComponent.new()]
    entity = Test.TestingEntity.new(components)
    {entity.id,components, pids}
  end


  def start_supervisor_with_monitor(arg \\ []) do
    Application.put_env(:ecstatic, :test_pid, self())               #monitor listener
    {:ok, supervisor} = Ecstatic.Supervisor.start_link(arg)
    {:ok, consumer} = Test.TestingEventConsumer.start_link(self())  #monitor speaker
    {:ok, [supervisor, consumer]}
  end
end
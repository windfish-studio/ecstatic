ExUnit.start()
defmodule TestHelper do
  alias Ecstatic.Aspect
  def ecs_id?(string) do
    {res,_} = UUID.info(string)
    res == :ok
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

  def aspect_one_sec_infinity do
    Aspect.new([Test.TestingComponent.OneComponent],[],[every: 1000, for: :infinity])
  end

  def aspect_real_time do
    Aspect.new([Test.TestingComponent.OneComponent],[],[every: :continuous, for: :infinity])
  end

  def aspect_one_sec_five_shots do
    %Aspect{with: [Test.TestingComponent.OneComponent], trigger_condition: [every: 1000, for: 5]}
  end

  def aspect_zero do
    Aspect.new([Test.TestingComponent.OneComponent],[],[every: :continuous, for: 0])
  end
end
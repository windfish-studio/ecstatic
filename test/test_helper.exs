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
      {:debug, _new, _} -> wait_receiver(timeout_time_milisec)
    after
      timeout_time_milisec -> :time_out
    end
  end

  def initialize(watcher \\ Test.TestingWatcher.OneSecInfinity) do
    Application.put_env(:ecstatic, :watchers, fn() -> watcher.watchers end)  #watchers definition
    Application.put_env(:ecstatic, :test_pid, self())                         #spy init
    {:ok, _pid} = Ecstatic.Supervisor.start_link([])
    component = Test.TestingComponent.new()
    entity = Test.TestingEntity.new([component])
    #wait_receiver()
    {entity.id,component}
  end
end
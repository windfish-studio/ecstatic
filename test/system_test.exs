defmodule SystemTest do
  use ExUnit.Case

  alias Ecstatic.TestingSystem
  alias Ecstatic.Changes

  @moduletag :capture_log

#  doctest TestingSystem

  setup_all do
    {:ok, _pid} = Ecstatic.Supervisor.start_link([])
    :ok
  end

#  setup do
#    Application.put_env(:ecstatic, :debug_pid, self())
#  end


  test "module exists" do
    assert is_list(System.module_info())
  end

  test "do_process no changes" do
    components = [Ecstatic.Component.new(Test,[])]
    entity = Ecstatic.Entity.new(components)
    function = fn entity -> %Changes{} end
#    assert do_process(entity, function) == {entity, %Changes{}}
  end
end

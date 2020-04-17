defmodule Test.TestingSystem do
  @moduledoc false
  alias Ecstatic.Entity
  use Ecstatic.System

  def aspect do
    Ecstatic.Aspect.new(with: [], without: [])
  end
  #non-reactive
  def dispatch(entity) do
    pid = Application.get_env(:ecstatic, :test_pid)
    send pid, "hello world"
    %Changes{}
  end
  #reactive
  def dispatch(entity,changes) do
    nil
  end
end

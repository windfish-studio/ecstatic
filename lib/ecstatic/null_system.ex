defmodule Ecstatic.NullSystem do
  @moduledoc false
  use Ecstatic.System
  def aspect, do: %Aspect{}
  require Logger
  def dispatch(_entity, _changes, _delta) do
    %Changes{}
  end
end

defmodule Ecstatic.NullSystem do
  @moduledoc false
  use Ecstatic.System
  def aspect, do: %Aspect{}

  def dispatch(_entity, nil, _delta) do
    %Changes{}
  end

  def dispatch(_entity, _changes, _delta) do
    %Changes{}
  end

  def process(_,_) do
    :ok
  end
end

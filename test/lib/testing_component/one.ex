defmodule Test.TestingComponent.OneComponent do
  @moduledoc false
  use Ecstatic.Component
  @default_state %{var: 0, f: 0}
#
#  def new(state) do
#    Component.new(__MODULE__,state)
#  end

  def inc(component) do
    new_state = %{component.state | var: component.state.var + 1}
    %{component | state: new_state}
  end

  def frequency(component, time) do
    f = case time do
      0 -> :infinity
      0.0 -> :infinity
      _ -> 1/time
    end
    new_state = %{component.state | f: f}
    %{component | state: new_state}
  end

  def x10(component) do
    new_state = %{component.state | var: component.state.var + 10}
    %{component | state: new_state}
  end
end
defmodule Test.TestingComponent.AnotherOneComponent do
  @moduledoc false
  use Ecstatic.Component
  @default_state %{var: 0, another_var: :zero}

  def dec(component) do
    new_state = %{component.state | var: component.state.var - 1}
    %{component | state: new_state}
  end
end
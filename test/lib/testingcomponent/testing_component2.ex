defmodule Test.TestingComponent2 do
  @moduledoc false
  use Ecstatic.Component
  @default_state %{var: 0, another_var: :zero}

  def inc(component) do
    new_state = %{component.state | var: component.state.var + 1}
    %{component | state: new_state}
  end
end

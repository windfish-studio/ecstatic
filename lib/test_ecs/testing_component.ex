defmodule TestEcs.TestingComponent do
  @moduledoc false
  use Ecstatic.Component
  @default_state %{var: 0, another_var: :zero}
end

defmodule Test.TestingEntity do
  @moduledoc false
  use Ecstatic.Entity
  alias Test.{TestingComponent,AnotherTestingComponent}
  @default_components [TestingComponent, AnotherTestingComponent]
end

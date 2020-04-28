defmodule Test.TestingAspect.NonReactive.OneSecInfinity do
  @moduledoc false
  use Ecstatic.Aspect
  alias Test.TestingComponent.OneComponent

  def new() do
    Aspect.new(
            with: [OneComponent],
            without: [],
            when: [every: 1000, for: :infinity])
  end

end
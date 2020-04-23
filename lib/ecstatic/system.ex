defmodule Ecstatic.System do
  alias Ecstatic.{Aspect, Changes, Entity}
  @callback aspect() :: Aspect.t()
  @callback dispatch(entity :: Entity.t(), optional_change) :: Changes.t()

  @type optional_change :: Changes.t() | nil

  @doc false
  defmacro __using__(_options) do
    quote location: :keep do
      @behaviour Ecstatic.System
      alias Ecstatic.{Aspect, Changes, Component, Entity, EventSource}

      @type dispatch_fun ::
              (Entity.t() -> Changes.t())
      @type event_push :: :ok

      @spec process(entity :: Entity.t(), delta :: number()) :: event_push()
      def process(entity, delta) do
        function = fn -> dispatch(entity, delta) end
        do_process(entity, function)
      end

      @spec process(entity :: Entity.t(), changes :: Changes.t(), delta :: number()) :: event_push()
      def process(entity, changes, delta) do
        function = fn -> dispatch(entity, changes, delta) end
        do_process(entity, function)
      end

      @spec do_process(Entity.t(), dispatch_fun()) :: event_push()
      defp do_process(entity, function) do
        event =
          if Entity.match_aspect?(entity, aspect()) do
            {entity, function.()}
          else
            {entity, %Changes{}}  #lets combine old and new
          end
        EventSource.push(event)
      end
    end
  end
end

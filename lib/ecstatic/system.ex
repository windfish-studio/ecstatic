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
              | (Entity.t(), Changes.t() -> Changes.t())
      @type event_push :: :ok

      @spec process(entity :: Entity.t(), nil) :: event_push()
      def process(entity, nil, delta) do
        function = fn -> dispatch(entity, nil, delta) end
        do_process(entity, function)
      end

      @spec process(entity :: Entity.t(), changes :: Changes.t()) :: event_push()
      def process(entity, changes, delta) do
        function = fn -> dispatch(entity, changes, delta) end
        do_process(entity, function)
      end

      @spec do_process(Entity.t(), dispatch_fun()) :: event_push()
      defp do_process(entity, function) do
        event =
          if Entity.match_aspect?(entity, aspect()) do
            merge_changes(entity,function.())
          else
            {entity, %Changes{}}  #lets combine old and new
          end
        EventSource.push(event)
      end

      defp merge_changes(entity, new_changes) do
        changes = Enum.map(new_changes.updated,
          fn new_c ->
            old_c = Enum.find(entity.components,
                fn old_c -> old_c.id == new_c.id end)
            {old_c, new_c}
          end)
        changes = %Changes{updated: changes}
        {entity, changes}
      end
    end
  end
end

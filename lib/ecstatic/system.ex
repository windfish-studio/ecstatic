defmodule Ecstatic.System do
  @moduledoc """
  define here how to use the system
  # This is a heading
  """
  alias Ecstatic.{Aspect, Changes, Entity}
  @type t :: module()
  @type optional_change :: Changes.t() | nil
  @callback aspect() :: Aspect.t
  @callback dispatch(Entity.t(), optional_change, delta :: number()) :: Changes.t()
  @doc false
  defmacro __using__(_options) do
    quote location: :keep do
      @behaviour Ecstatic.System
      alias Ecstatic.{Aspect, Changes, Component, Entity, EventSource}
      @type dispatch_fun :: (() -> number())
      @type event_push :: :ok

      @spec process(entity :: Entity.t(), changes :: Changes.t(), delta :: number()) :: event_push()
      def process(entity, changes, delta \\ 0) do
        function = fn -> dispatch(entity, changes, delta) end
        do_process(entity, function)
      end

      @spec do_process(Entity.t(), dispatch_fun()) :: event_push()
      defp do_process(entity, function) do
        changes = function.()
        changes = %{changes | caused_by: changes.caused_by ++ [__MODULE__]}
        event = {entity, changes}
        EventSource.push(event)
      end
    end
  end
end

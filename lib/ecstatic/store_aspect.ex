defmodule Ecstatic.Store.Aspect do
  alias Ecstatic.Aspect

  @spec get_aspects() :: [Aspect.t()]
  def get_aspects() do
    [aspects: aspects] = :ets.lookup(__MODULE__, :aspects)
    aspects
  end

  @spec new(aspect :: Aspect.t()) :: :ok
  def new(aspect) do
    :ets.new(__MODULE__, [:named_table, :protected, :set])
    :ets.insert(__MODULE__, {:aspects, aspect})
    require Logger
    Logger.debug(inspect({"new Store Aspect. aspect added: ", aspect}))
    :ok
  end

  defp reduce(aspect_modules) do
    Enum.reduce(aspect_modules, [], fn aspect_module, sum ->
      sum ++ aspect_module
    end)
  end

  def insert(aspect) do
    aspects = :ets.lookup(__MODULE__, :aspects)
    |> Kernel.++(aspect)
    :ets.insert(__MODULE__, {:aspects, reduce(aspects)})
    :ok
  end
end
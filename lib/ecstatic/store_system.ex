defmodule Ecstatic.Store.System do
  alias Ecstatic.System

  @spec get_systems() :: [System.t()]
  def get_systems() do
    [systems: systems] = :ets.lookup(__MODULE__, :systems)
    systems
  end

  @spec new(aspects :: [Aspect.t()]) :: :ok
  def new(systems \\ []) do
    :ets.new(__MODULE__, [:named_table, :protected, :set])
    :ets.insert(__MODULE__, {:systems, systems})
    :ok
  end

  defp reduce(system_modules) do
    Enum.reduce(system_modules, [], fn system_module, sum ->
      sum ++ system_module
    end)
  end

  def insert(system) do
    systems = :ets.lookup(__MODULE__, :systems)
    |> Kernel.++(system)
    :ets.insert(__MODULE__, {:systems, reduce(systems)})
    :ok
  end
end
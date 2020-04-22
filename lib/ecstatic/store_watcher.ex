defmodule Ecstatic.Store.Watcher do
  def get_watchers() do
    [watchers: watchers] = :ets.lookup(__MODULE__, :watchers)
    watchers
  end

  def new(watchers_modules) do
    :ets.new(__MODULE__, [:named_table, :protected, :set])
    :ets.insert(__MODULE__, {:watchers, reduce(watchers_modules)})
  end

  defp reduce(watchers_modules) do
    Enum.reduce(watchers_modules, [], fn watcher_module, sum ->
      sum ++ watcher_module.watchers
    end)
  end
end
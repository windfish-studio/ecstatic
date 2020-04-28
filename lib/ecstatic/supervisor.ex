defmodule Ecstatic.Supervisor do
  @moduledoc false
  use Supervisor
  @type reply() :: :ignore | {:error, any()} | {:ok, pid()}

  @spec start_link(arg :: keyword(module())) :: reply()
  def start_link(arg \\ []) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(arg) do
    children = [
      {Ecstatic.Store.Ets, []},
      {Ecstatic.EventSource, []},
      {Ecstatic.EventProducer, []}
    ]
    Keyword.get(arg, :systems, [])
    |> Enum.map(fn system ->
                            require Logger
                            Logger.debug(inspect({"Supervisor init, aspect is: ", system.aspect}))
                            system.aspect.new()
                end)
    Supervisor.init(children, strategy: :one_for_one)
  end
end

defmodule Ecstatic.Supervisor do
  require Logger
  @moduledoc false
  use Supervisor

  def start_link(arg \\ []) do
    Logger.debug()
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(arg) do
    children = [
      {Ecstatic.Store.Ets, []},
      {Ecstatic.EventSource, []},
      {Ecstatic.EventProducer, []}
    ]
    #lets put args somewhere useful. The watchers might be stored in the Ets or maybe in another genserver
    #Ecstatic.Store.Watchers.get_watchers

    Supervisor.init(children, strategy: :one_for_one)
  end
end

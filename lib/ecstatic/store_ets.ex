defmodule Ecstatic.Store.Ets do
  @behaviour Ecstatic.Store
  use GenServer
  require Logger

  def start_link(opts \\ %{}) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    :ets.new(__MODULE__, [:named_table, :protected, :set])
    {:ok, opts}
  end

  @impl true
  def save_entity(entity) do
    Logger.debug("Saving entity in ETS")
    GenServer.call(__MODULE__, {:save_entity, entity})
  end

  @impl true
  def delete_entity(id) do
    Logger.debug("Destroying entity in ETS")
    GenServer.cast(__MODULE__, {:delete_entity, id})
  end

  @impl true
  def get_entity(id) do
    m = :ets.match(__MODULE__, {{:entity, id}, :"$1"})
    case m do
      [[entity]] -> entity
      [] -> nil
    end
  end

  @impl true
  def handle_call({:save_entity, entity}, _from, state) do
    :ets.insert(__MODULE__, {{:entity, entity.id}, entity})
    {:reply, entity, state}
  end

  @impl true
  def handle_cast({:delete_entity, id}, state) do
    :ets.match_delete(__MODULE__, {{:entity, id}, :"$1"})
    {:noreply, state}
  end
end

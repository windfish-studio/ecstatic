defmodule Ecstatic.EntityManager do
  @moduledoc false
  use GenServer
  alias Ecstatic.{
    Entity,
    EventConsumer,
    Component,
    Store,
    Changes,
    EventSource}

  def start_link(arg \\ []) do
    GenServer.start_link(__MODULE__, arg, [name: __MODULE__])
  end

  def init(_arg \\ []) do
    {:ok, nil}
  end

  def handle_call({:create, components}, _from, state) do
    entity = %Entity{id: Entity.id()}
    {:ok, consumer_pid} = EventConsumer.start_link(entity)
    entity = %{entity | consumer_pid: consumer_pid}
    {init, non_init} = Enum.split_with(components, fn
      %Component{} -> true
      _ -> false
    end)
    Entity.build(entity, Enum.concat(init, non_init))
    Store.Ets.save_entity(entity)
    {:reply, entity, state}
  end

  def handle_cast({:destroy, entity}, state) do
    cPid= entity.consumer_pid
    Store.Ets.delete_entity(entity.id)
    Process.unlink(cPid)
    EventConsumer.stop(cPid)
    {:noreply, state}
  end

  @spec create_entity([Component.t()]) :: Entity.t
  def create_entity(components) do
    GenServer.call(__MODULE__, {:create, components})
  end

  @spec destroy_entity([Entity.t()]) :: no_return()
  def destroy_entity(entity) do
    GenServer.cast(__MODULE__, {:destroy, entity})
  end
end

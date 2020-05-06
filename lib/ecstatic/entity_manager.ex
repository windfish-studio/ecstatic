defmodule Ecstatic.EntityManager do
  @moduledoc false
  use GenServer
  alias Ecstatic.{
    Entity,
    EventConsumer,
    Component,
    Store,
    Changes}

  def start_link(arg \\ []) do
    require Logger
    Logger.debug("running EntityManager")
    GenServer.start_link(__MODULE__, arg, [name: __MODULE__])
  end

  def init(_arg \\ []) do
    {:ok, nil}
  end

  def handle_call({:create, components}, _from, state) do
    require Logger
    Logger.debug("call creating")
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

  def handle_call({:destroy, entity}, _from, state) do
      Store.Ets.delete_entity(entity.id)
      EventConsumer.stop(entity.consumer_pid, :entity_destroy)
      {:noreply, state}
  end

  @spec create_entity([Component.t()]) :: Entity.t
  def create_entity(components) do
    require Logger
    Logger.debug("creating entity")
    GenServer.call(__MODULE__, {:create, components})
  end

  @spec destroy_entity([Entity.t()]) :: no_return()
  def destroy_entity(entity) do
    GenServer.call(__MODULE__, {:destroy, entity})
  end

  @spec build(Entity.t(), [Component.t()]) :: Entity.t()
  defp build(%Entity{} = entity, components) do
    changes = %Changes{attached: components}
    initialized_components = Entity.new_list_of_components(entity, changes)
    EventSource.push({entity, %Changes{attached: initialized_components}})
    %Entity{entity | components: components}
  end
end

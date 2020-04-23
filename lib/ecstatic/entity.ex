defmodule Ecstatic.Entity do
  alias Ecstatic.{
    Entity,
    EventSource,
    Component,
    Aspect,
    Changes,
    Store
  }
  defstruct [:id, components: []]

  @type id :: String.t()
  @type uninitialized_component :: atom()
  @type components :: list(Component.t())
  @type t :: %Entity{
          id: String.t(),
          components: components
        }

  defmacro __using__(_options) do
    quote location: :keep do
      Module.register_attribute(__MODULE__, :default_components, [])
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      @default_components @default_components || []
      def new(components \\ []) do
        #filter out any components passed in which are duplicates of default components
        passed_comp_modules = Enum.reduce(components, %{}, fn(comp, acc) -> Map.put(acc, comp.type, false) end)
        default_comps = Enum.filter(@default_components, fn(def_comp) -> 
          Map.get(passed_comp_modules, def_comp, true)
        end)
        Ecstatic.Entity.new(components ++ default_comps)
      end
    end
  end

  @doc "Creates a new entity"
  @spec new([Ecstatic.Component.t()]) :: t
  def new(components) when is_list(components) do
    entity = %Entity{id: id()}
    Ecstatic.EventConsumer.start_link(entity)
    {init, non_init} = Enum.split_with(components, fn
      %Component{} -> true
                  _ -> false
    end)
    build(entity, Enum.concat(init, non_init))
    Store.Ets.save_entity(entity)
  end

  @spec build(t(), [Component.t()]) :: t()
  defp build(%Entity{} = entity, components) do
    changes = %Changes{attached: components}

    initialized_components = new_list_of_components(entity, changes)

    EventSource.push({entity, %Changes{attached: initialized_components}})

    %Entity{entity | components: components}
  end

  @doc "Add an initialized component to an entity"
  @spec add(t, Component.t()) :: t
  def add(%Entity{} = entity, %Component{} = component) do
    EventSource.push({entity, %Ecstatic.Changes{attached: [component]}})
    entity
  end

  @doc "Checks if an entity matches an aspect"
  @spec match_aspect?(t, Aspect.t()) :: boolean
  def match_aspect?(entity, aspect) do
    Enum.all?(aspect.with, &has_component?(entity, &1)) &&
      !Enum.any?(aspect.without, &has_component?(entity, &1))
  end

  @doc "Check if an entity has an instance of a given component"
  @spec has_component?(t, uninitialized_component) :: boolean
  def has_component?(entity, component) do
    entity.components
    |> Enum.map(& &1.type)
    |> Enum.member?(component)
  end

  @spec find_component(t, uninitialized_component) :: Component.t() | nil
  def find_component(entity, component) do
    Enum.find(entity.components, &(&1.type == component))
  end

  @spec apply_changes(t(), Changes.t()) :: t()
  def apply_changes(entity, changes) do
    new_comps = new_list_of_components(entity, changes)
    new_entity = %Entity{entity | components: new_comps}
    Store.Ets.save_entity(new_entity)
    new_entity
  end

  defp id, do: Ecstatic.ID.new()

  @spec new_list_of_components(t(), Changes.t()) :: [Component.t()]
  defp new_list_of_components(
         entity,
         %Changes{attached: attached, updated: updated, removed: removed}
       ) do
    comps_to_attach =
      Enum.map(attached, fn
        %Component{} = c -> c
        c when is_atom(c) -> c.new
      end)
    updated
    |> Enum.map(fn upd ->
                  case upd do
                     {_old,new} -> new
                     new -> new
                  end
                end) ##updated now is a tupple
    |> Enum.concat(entity.components)
    |> Enum.uniq_by(& &1.id)
    |> Enum.concat(comps_to_attach)
    |> Enum.uniq_by(& &1.type)
    |> Enum.reject(&Enum.member?(removed, &1.type))
  end
end

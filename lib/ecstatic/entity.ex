defmodule Ecstatic.Entity do
  @moduledoc """
  Entities are the stuff in our project. They can always be described with nouns, like *Car*, *Human* or *Planet*. It's definition is really short, because it's behaviour SHOULD NOT be defined here. For that purpose we should use Ecstatic.System and Ecstatic.Component instead. That's because of ECS philosophy. If we want to exploit the polymorphism that ECS offers us, we must keep the entity as simpler as possible.
  ## Configuration:

  Entities are mostly defined by its components. For example, we could define a human like this:
  ```
  defmodule Human do
    use Ecstatic.Entity
    @default_components [Positionable, Age]
  end
  ```
  We had added the component *Positionable* because our Human will be in a certain position in a our world. Also, we want to take into account that this human will get old, so we had also defined that they can *Age*.

  ## Entity dynamics:
  By default, we can create entities with new:
  ```
    Human.new()
  ```
  Moreover, if we want to add specific components to our Entity we could do so. For example, let's add superpowers to our Human.
  ```
    Human.new([Superpowerful])
  ```
  > where Superpowerful is an Ecstatic.Component.
  """
  alias Ecstatic.{
    Entity,
    EntityManager,
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
    EntityManager.create_entity(components)
  end

  @doc "Destroys the entity"
  @spec destroy(t()) :: no_return()
  def destroy(entity) do
    EntityManager.destroy_entity(entity)
    nil
  end

  @doc "Add an initialized component to an entity."
  @spec add(t, Component.t()) :: t
  def add(%Entity{} = entity, %Component{} = component) do
    EventSource.push({entity, %Ecstatic.Changes{attached: [component]}})
    entity
  end

  @doc "Updates the entity with the specified changes"
  @spec change(Entity.t, Changes.t) :: no_return
  def change(entity, changes) do
    EventSource.push({entity, changes})
  end

  @doc "Checks if an entity matches an aspect."
  @spec match_aspect?(t, Aspect.t) :: boolean
  def match_aspect?(entity, aspect) do
    Enum.all?(aspect.with, &has_component?(entity, &1)) &&
      !Enum.any?(aspect.without, &has_component?(entity, &1))
  end

  @doc "Check if an entity has an instance of a given component."
  @spec has_component?(t, uninitialized_component) :: boolean
  def has_component?(entity, component) do
    entity.components
    |> Enum.map(& &1.type)
    |> Enum.member?(component)
  end

  @doc "Get the specific component from an entity"
  @spec find_component(t, uninitialized_component) :: Component.t() | nil
  def find_component(entity, component) do
    Enum.find(entity.components, &(&1.type == component))
  end

  @doc false
  @spec build(t(), [Component.t()]) :: t()
  def build(%Entity{} = entity, components) do
    changes = %Changes{attached: components}
    initialized_components = new_list_of_components(entity, changes)
    EventSource.push({entity, %Changes{attached: initialized_components}})
    %Entity{entity | components: components}
  end

  @doc false
  @spec apply_changes(t(), Changes.t()) :: t() | nil
  def apply_changes(entity, changes) do
      new_comps = new_list_of_components(entity, changes)
      new_entity = %Entity{entity | components: new_comps}
      Store.Ets.save_entity(new_entity)
      new_entity
  end

  def id, do: Ecstatic.ID.new()

  @doc false
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

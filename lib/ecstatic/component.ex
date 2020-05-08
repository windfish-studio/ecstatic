defmodule Ecstatic.Component do
  @moduledoc """
  Components are the basic piece. They are defined as behaviours, skills or functionality is needed. They are often names with abilities or adjetives, like *Positionable* or *
"""
  alias Ecstatic.Component
  defstruct [:id, :state, :type]

  @type params :: map()
  @type id :: String.t()
  @type component_type :: atom()
  @type state :: map()
  @type t :: %Component{
          type: component_type,
          state: state,
          id: id
        }

  defmacro __using__(_options) do
    quote location: :keep do
      Module.register_attribute(__MODULE__, :default_state, [])
      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      @default_state @default_state || %{}
      def new(initial_state \\ %{}) do
        Component.new(
          __MODULE__,
          Map.merge(@default_state, initial_state)
        )
      end
    end
  end

  @doc "New component"
  @spec new(component_type, state) :: t
  def new(component_type, initial_state) do
    id = Ecstatic.ID.new()

    struct(
      __MODULE__,
      %{id: id, type: component_type, state: initial_state}
    )
  end

  # TODO implement a "change" API to fix abstraction leak in systems
end

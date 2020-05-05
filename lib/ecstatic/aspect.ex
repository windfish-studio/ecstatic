defmodule Ecstatic.Aspect do
  alias Ecstatic.{Component, Entity, Changes, System}
  #Aspect defines whether the calling system should run. Here, we define for which entities or components
  #at which condition, how many times or with how many frequency

  defstruct with: [],
            without: [],
            trigger_condition: [every: :continuous, for: 1]

  @type timer_specs :: [every: number | :continuous,
                         for: timeout()]

  @type changes_types :: :attached | :removed | :updated
  @type lifecycle_hook :: MapSet.t(changes_types())
  @type react_fun :: (System.t, Entity.t(), Changes.t() -> boolean())
  @type react_specs :: [condition: react_fun(), lifecycle: lifecycle_hook]


  @type t :: %Ecstatic.Aspect{
               with: [Component.t()],
               without: [Component.t()],
               trigger_condition: timer_specs | react_specs
             }

  @spec new([Component.t()], [Component.t()], timer_specs | react_specs) :: t()
  def new(with_components, without_components, cond)
      when is_list(without_components)
           when is_list(with_components) do
    %Ecstatic.Aspect{
      with: with_components,
      without: without_components,
      trigger_condition: cond
    }
  end

  @spec is_reactive(t()) :: boolean()
  def is_reactive(aspect) do
    Kernel.match?([condition: _, lifecycle: _], aspect.trigger_condition)
  end
end

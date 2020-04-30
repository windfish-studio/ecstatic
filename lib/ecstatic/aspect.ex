defmodule Ecstatic.Aspect do
  #Aspect defines whether the calling system should run. Here, we define for which entities or components
  #at which condition, how many times or with how many frequency

  defstruct with: [],
            without: [],
            trigger_condition: [every: :continuous, for: 1]

  @type timer_specs :: [every: number | :continuous,
                         for: timeout()] #todo: is 0 or :stopped allowed?

  @type changes_types :: :attached | :removed | :updated
  @type lifecycle_hook :: MapSet.t()      #todo: define better this set
  @type react_fun :: fun()                #todo: define better this function
  @type react_specs :: [fun: react_fun(), lifecycle: lifecycle_hook]


  @type t :: %Ecstatic.Aspect{
               with: [Ecstatic.Component.t()],
               without: [Ecstatic.Component.t()],
               trigger_condition: timer_specs | react_specs
             }

  @spec new([Ecstatic.Component.t()], [Ecstatic.Component.t()], timer_specs | react_specs) :: t()
  def new(with_components, without_components, cond)
      when is_list(without_components)
           when is_list(with_components) do
    %Ecstatic.Aspect{
      with: with_components,
      without: without_components,
      trigger_condition: cond
    }
  end
end

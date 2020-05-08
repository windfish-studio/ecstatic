defmodule Ecstatic.Aspect do
  @moduledoc """
  # Aspect
  The aspect is a useful filter, in order to optimize systems races. Hadn't we this filter, all systems would be running at the same time. So, its mandatory for every system to have defined an =aspect()=
  Aspect defines whether the calling system should run. Here, can define:
  - for which entities or components the system will run
  - at which conditions
  - how many times or with how many frequency

  The aspect declares the conditions whenever the system has to execute. These conditions are:
  - `:with`: the aspect matches if the entity involved has all of these listed components.
  - `:without`: the aspect matches if the entity has non of these listed components.
  - `:triggered_condition`: the aspect matches if the entity and the changes match our conditions. We have to notice that we can declare two types of systems: timed systems or reactive systems. It relies on how we had specified this key. Let's see it in depth:

  ## Aspect for timed systems
  Timed systems will be executed with the following time specifications.
  For timed systems, we have to define 2 keys:
  - `:every`: this is the period time (in miliseconds) at the dispatch updates the changes. If we want to run the system as frequent as possible, put `:continuous` instead.
  - `:for`: this is the number of times the system will dispatch. If we want to run the system forever, we can put `:infinity`, instead of a positive integer.

  Three examples, of how to declare ':triggered_condition` for timed systems:

  1. With this `:triggered_condition`, the system will trigger 3 times: in t=0sec, t=1sec and t=2sec.
  ```
    triggered_condition: [every: 1000, for: 3]
  ```
  2. Now, =for= has no limitations, so the system will trigger one time per second
  ```
    triggered_condition: [every: 1000, for: :infinity]  #The system will trigger 1 time per second.
  ```
  3. We could define a system that triggers as much as it can. But look out, real time systems could lead as to a bad performance.
  ```
    triggered_condition: [every: :continuous, for: :infinity]
  ```

  ## Aspect for reactive systems
  On the other hand, reactive systems are asynchronous. They will dispatch changes when conditions related with the changes itself or the entity are matching, as the user would like to define.
  For reactive systems, we have to also define 2 keys;
  - `:lifecycle` this is the kind of changes that the system expects. It can be `:attached`, `:updated` and/or `:removed`.
  - `:condition` here the user must define a function that returns whether the condition has been matched or not.
  Examples:
  ```
    triggered_condition: [lifecycle: [:attached] , condition: fn (_entity, _changes) -> true end)] #the system will trigger everytime any of the components are added to the entity
  ```
  In this example, the dispatch is executed when the entity has the new specific component.

  ```
    triggered_condition: [lifecycle: [:updated], condition: fn (_entity, changes) ->
     [{_old,updated_component}] = changes.updated
     updated_component.the_variable > 0
    end)]
  ```
  In this example, the dispatch is executed only if the recently updated variable is positive.

  """

  alias Ecstatic.{Component, Entity, Changes, System}

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
  def new(with_components, without_components, condition)
      when is_list(without_components)
           when is_list(with_components) do
    %Ecstatic.Aspect{
      with: with_components,
      without: without_components,
      trigger_condition: condition
    }
  end

  @spec is_reactive(t()) :: boolean()
  def is_reactive(aspect) do
    Kernel.match?([condition: _, lifecycle: _], aspect.trigger_condition)
  end
end

defmodule Ecstatic.Changes do
  @moduledoc """
  Changes is a struct where we can observe and define changes happened in one Ecstatic.Entity. When the user is currently defining the aspect and the system, they will recognize this structure. We must realize that Changes has two purposes:
  1. Receiving it as a parameter to determine whether our reactive system will trigger. See Ecstatic.aspect
  2. Sending it as the expected output of any dispatch. See Ecstatic.System.dispatch\3

  Let's define the changes's keys and what's their purpose

  ## Attached
  Attached is related with the assignation of new components to the entity. In fact, if the entity has been just created, these components will already appear here. We can put components here if we want to notify the creation of new components. However, it's recommended to use Ecstatic.Entity.add\2 instead.

  ## Removed
  On the other hand, removed implies that a component in the entity had been removed...

  ## Updated
  If the state of some components had changed, those components will appear in this list. The aspect will receive the last version of the component, BUT ALSO, the previous one.
  The following example is a typical pattern matching to use in a function defined in `:condition`. See the Ecstatic.Aspect. The Aspect detects that some components (c1 and c2) had changed. That's useful to compare against values (checking only the new component) or increments (comparing both).
  ```
  condition: fn (_entity, changes) ->
    [{c1_old, c1_new}, {c2_old, c2_new}] = changes.updated
  end
  ```

  On the other hand, when we have to define the dispatch's output, the tuple with duplicated components are no longer necessary. We must prepare the changes with the components that we had only changed.
  Matching the condition of the example above, let's say that our dispatch has updated our components, with new_states:
  ```
  dispatch (_e, changes, _d) do
    [{c1_old, c1_new}, {c2_old, c2_new}] = changes.updated
    c1 = {c1 | state: new_state1}
    c2 = {c2 | state: new_state2}
    %Ecstatic.Changes{updated: [c1, c2]}
  end
  ```
  Notice that we hadn't used tuples.

  ## Caused by
  For every change we make in our system, an instigator will be added, in order to tag which systems had made current changes.

  #The logger
  Whenever an Entity is created or some changes has successfully dispatched by a System, the logger will register these changes for debug purposes.

"""
  defstruct attached: [],
            updated: [],
            removed: [],
             caused_by: []

  @type attached_component :: atom() | Ecstatic.Component.t()
  @type updated_component :: {Ecstatic.Component.t(),Ecstatic.Component.t()} | Ecstatic.Component.t()

  @type t :: %Ecstatic.Changes{
          attached: [attached_component],
          updated: [updated_component],
          removed: [atom()],
          caused_by: [module()]
        }
end

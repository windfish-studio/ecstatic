defmodule Ecstatic.Changes do
  defstruct attached: [],
            updated: [],
            removed: [],
             removed_entity: [],
             caused_by: []

  @type attached_component :: atom() | Ecstatic.Component.t()
  @type updated_component :: {Ecstatic.Component.t(),Ecstatic.Component.t()} | Ecstatic.Component.t()

  @type t :: %Ecstatic.Changes{
          attached: [attached_component],
          updated: [updated_component],
          removed: [atom()],
          removed_entity: [Ecstatic.Entity.t],
          caused_by: [module()]
        }
end

defmodule Ecstatic.Changes do
  defstruct attached: [],
            updated: [],
            removed: []

  @type attached_component :: atom() | Ecstatic.Component.t()
  @type updated_component :: {Ecstatic.Component.t(),Ecstatic.Component.t()} | Ecstatic.Component.t()

  ## updated has the new and the old component
  @type t :: %Ecstatic.Changes{
          attached: [attached_component],
          updated: [updated_component],
          removed: [atom()]
        }
end

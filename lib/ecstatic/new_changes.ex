defmodule Ecstatic.NewChanges do
  defstruct attached: [],
            updated: [],
            removed: []

  @type attached_component :: atom() | Ecstatic.Component.t()

  ## updated has the new and the old component
  @type t :: %Ecstatic.NewChanges{
          attached: [attached_component],
          updated: [ Ecstatic.Component.t()],
          removed: [atom()]
        }
end

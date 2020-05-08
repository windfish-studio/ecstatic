defmodule Ecstatic.Store do
  @moduledoc false
  alias Ecstatic.Entity

  @type return_type :: {:ok, Entity.t()} | {:error, term()}
  @type entity_id_type :: pos_integer() | String.t()
  @callback save_entity(Entity.t()) :: Entity.t()
  @callback get_entity(entity_id_type) :: return_type
  @callback delete_entity(entity_id_type) :: :ok
end

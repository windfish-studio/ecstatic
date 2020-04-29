defmodule Ecstatic.Ticker do
  #One for each Entity
  @type component_id :: String.t
  @type system_name :: atom()
  @type system_component_pair :: {component_id, system_name}

@type t :: %__MODULE__{
  ticks_left: %{system_component_pair => non_neg_integer()},
  last_tick_time: %{system_component_pair => float()}
}
  def get_time() do
    t=DateTime.utc_now()
    |>DateTime.truncate(:microsecond)
    |>DateTime.to_unix(:microsecond)
    t/1000000
  end

  defstruct [
    ticks_left: %{},
    last_tick_time: %{}
  ]
  use GenServer

  def start_link(), do: start_link(nil)
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil)
  end

  def init(_opts) do 
    {:ok, %Ecstatic.Ticker{}}
  end

  defp update_last_tick_time(state, system, new_time) do
    new_last_tick_time = Map.put(state.last_tick_time, system, new_time)
    %__MODULE__{state | last_tick_time: new_last_tick_time}
  end

  defp update_ticks_left(state, system, new_ticks_left) do
    new_ticks_left = Map.put(state.ticks_left, system, new_ticks_left)
    %__MODULE__{state | ticks_left: new_ticks_left}
  end

  defp delta(state, system, new_time) do
    new_time - Map.get(state.last_tick_time, system, new_time)
  end

  def handle_info({:tick, e_id, system}, state) do
    case Map.get(state.ticks_left, system, nil) do  #this nil will trigger an error on purpose
      t_left 
        when t_left == :infinity 
        when (is_number(t_left) and t_left > 0) ->
          entity = Ecstatic.Store.Ets.get_entity(e_id)
          t = get_time()
          delta = delta(state, system, t)
          state = update_last_tick_time(state, system, t)
          system.process(entity, %Ecstatic.Changes{}, delta)
          case t_left do 
            :infinity -> {:noreply, state}
            _ -> {:noreply, update_ticks_left(state, system, (t_left - 1))}
          end
      0 ->
        {:noreply, update_ticks_left(state, system, :stopped)}
      :stopped -> 
        {:noreply, state}
    end
  end

  def handle_info({:start_tick, entity_id, system}, state) do
    send(self(), {:tick, entity_id , system})
    case system.aspect().when do
      [every: _, for: ticks] -> {:noreply, update_ticks_left(state, system, ticks)}
      _ -> nil
    end
  end

  def handle_info({:stop_tick, system}, state) do
    {:noreply, update_ticks_left(state, system, :stopped)}
  end
end
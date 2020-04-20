defmodule Ecstatic.Ticker do
  #One for each Entity
  @type component_id :: String.t
  @type system_name :: atom()
  @type system_component_pair :: {component_id, system_name}

@type t :: %__MODULE__{
  ticks_left: %{system_component_pair => non_neg_integer()},
  last_tick_time: %{system_component_pair => non_neg_integer()}
}
  def get_time() do
    DateTime.utc_now()
    |>DateTime.truncate(:microsecond)
    |>DateTime.to_unix()
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

  defp update_ticks(state, {c_id, system}, tick, new_time \\ get_time) do
    new_ticks_left = Map.put(state.ticks_left, {c_id, system}, tick)
    new_last_tick_time = Map.put(state.last_tick_time, {c_id, system}, new_time)
    %__MODULE__{ticks_left: new_ticks_left, last_tick_time: new_last_tick_time}
  end

  defp delta(state, {c_id, system}, new_time \\ get_time) do
    new_time - Map.get(state.last_tick_time, {c_id, system}, new_time)
  end

  def handle_info({:tick, c_id, e_id, system}, state) do
    IO.inspect({c_id,system})
    case Map.get(state.ticks_left, {c_id, system}, nil) do  #this nil will trigger the error
      t_left 
        when t_left == :infinity 
        when (is_number(t_left) and t_left > 0) ->
          entity = Ecstatic.Store.Ets.get_entity(e_id)
          t = get_time()
          delta = delta(state, {c_id, system}, t)
          system.process(entity, nil, delta)  #changes: nil
          case t_left do 
            :infinity -> {:noreply, state}
            _ -> {:noreply, update_ticks(state, {c_id, system}, (t_left - 1), t)}
          end
      0 ->
        {:noreply, update_ticks(state, {c_id, system}, :stopped)}
      :stopped -> 
        {:noreply, state}
    end
  end

  def handle_info({:start_tick, c_id, e_id, system, [every: _interval, for: ticks]}, state) do
    send(self(), {:tick, c_id, e_id, system})
    {:noreply, update_ticks(state, {c_id, system}, ticks)}
  end

  def handle_info({:stop_tick, c_id, system}, state) do
    {:noreply, update_ticks(state, {c_id, system}, :stopped)}
  end
end
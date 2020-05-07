defmodule Ecstatic.EventConsumer do
  @moduledoc false
  use GenStage
  require Logger
  alias Ecstatic.{Entity, Changes, Aspect}

  def start_link(entity) do
    GenStage.start_link(__MODULE__, entity)
  end

  def stop(a,b\\ :normal, t \\ 5000) do
    GenStage.stop(a,b,t)
  end

  def init(entity) do
    {:ok, ticker_pid} = Ecstatic.Ticker.start_link()
    Registry.register(MyRegistry, self(), ticker_pid)
    state = %{
      systems: Ecstatic.Store.System.get_systems(),
      entity_id: entity.id
    }

    {:consumer, state,
     subscribe_to: [
       {
         Ecstatic.EventProducer,
         selector: fn {event_entity, _changes} ->
           event_entity.id == entity.id
         end,
         max_demand: 1,
         min_demand: 0
       }
     ]}
  end

  def systems_to_aspects(systems) do
    Enum.map(systems, fn s -> s.aspect() end)
  end

  # I can do [event] because I only ever ask for one.
  # event => {entity, %{changed: [], new: [], deleted: []}}
  def handle_events([{entity, %Changes{} = changes} = _event], _from, %{systems: systems} = state) do
    systems = Enum.filter(systems, valid_components?(changes)) #discard systems with wrong components
    changes = merge_changes(entity, changes)  #cannot reduce complex changes in valid_components
    Logger.debug(Kernel.inspect(changes, pretty: true))
    systems = Enum.filter(systems, valid_condition?(entity, changes))
    new_entity = Entity.apply_changes(entity, changes)
    Enum.each(systems, fn system_mod ->
      if Aspect.is_reactive(system_mod.aspect()) do
       system_mod.process(new_entity, changes)
      else
        Enum.each(fields_not_empty(changes), fn change_type ->
        [{_,ticker_pid}] = Registry.lookup(MyRegistry, self())
          case change_type do
            :attached ->
              send(ticker_pid, {:start_tick, entity.id, system_mod})
            :updated ->
              case system_mod.aspect().trigger_condition do
                [every: t, for: _] when is_number(t) ->
                  Process.send_after(ticker_pid, {:tick, entity.id, system_mod}, t)
                _ ->
                  send(ticker_pid, {:tick, entity.id, system_mod})
              end
            :removed ->
              send(ticker_pid, {:stop_tick, entity.id, system_mod})
          end
        end)
      end
    end)
    {:noreply, [], state}
  end

  def valid_components?(changes) do
    components_detected = reduce_changes(changes)
    fn system ->
      match_with_condition =
      Enum.all?(system.aspect().with, fn component ->
        Enum.any?(components_detected, fn c -> component == c end)
      end)

#      match_without_condition =
      system.aspect().without == [] ||
      (Enum.any?(system.aspect().without, fn component ->
        Enum.any?(components_detected, fn c -> component == c end)
      end))
      |> Kernel.&&(match_with_condition)
    end
  end

  defp reduce_changes(changes) do
    changes.attached ++ changes.updated ++ changes.removed
    |> Enum.map(fn c -> c.type end)
    |> MapSet.new()
  end

  defp valid_condition?(entity, changes) do
    fn system_m ->
      is_caused_by_system_m = Enum.any?(changes.caused_by, fn s -> s == system_m end)
      case {system_m.aspect().trigger_condition, {is_caused_by_system_m, changes.updated}} do
        {[every: _period, for: :stopped], {_, _}} -> false
        {[every: _period, for: 0], {_, _}} -> false
        {[every: _period, for: _ticks_left], {true, _}} -> true
        {[every: _period, for: _ticks_left], {_, []}} -> true
        {[every: _, for: _], {_, _}} -> false

        {[condition: fun, lifecycle: lifecycle], _} ->
          detect_changes_type(changes, lifecycle)
          |> Kernel.&&(fun.(changes.caused_by, entity, changes))
        _ -> raise "consumer.valid_condition: system_m not expected"
      end
    end
  end

  defp detect_changes_type(changes, lifecycle) do
    [:attached, :updated, :removed]
    |> Enum.reduce(MapSet.new(), fn type, set ->
      detect_changes_type(set, changes, type)
    end)
    |> MapSet.intersection(MapSet.new(lifecycle))
    |> Kernel.!=(MapSet.new())
  end

  defp fields_not_empty(changes) do
    field_not_empty(changes, :attached) ++
    field_not_empty(changes, :updated) ++
    field_not_empty(changes, :removed)
  end

  defp field_not_empty(changes, field) do
    case Map.get(changes, field) != [] do
      true -> [field]
      _ -> []
    end
  end

  defp detect_changes_type(set, changes, field) do
    case Map.get(changes, field) do
      [] -> set
      _ -> MapSet.put(set, field)
    end
  end

  @spec merge_changes(Entity.t(), Changes.t()) :: Changes.t()
  defp merge_changes(entity, new_changes) do
    changes_updated = Enum.map(new_changes.updated,
      fn new_c ->
          old_c = Enum.find(entity.components,
            fn old_c -> old_c.id == new_c.id end)
          {old_c, new_c}
      end)
    %{new_changes | updated: changes_updated}
  end
end

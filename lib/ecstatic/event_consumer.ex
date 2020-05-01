defmodule Ecstatic.EventConsumer do
  @moduledoc false
  use GenStage
  require Logger

  alias Ecstatic.{Entity, Changes, Aspect}

  def start_link(entity) do
    GenStage.start_link(__MODULE__, entity)
  end

  def init(entity) do
    {:ok, ticker_pid} = Ecstatic.Ticker.start_link()
    state = %{
      systems: Ecstatic.Store.System.get_systems(),
      entity_id: entity.id,
      ticker: ticker_pid
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
    Logger.debug(Kernel.inspect(changes, pretty: true))
    systems = Enum.filter(systems, valid_components?(changes)) #discard systems with wrong components
    changes = merge_changes(entity, changes)  #cannot reduce complex changes in valid_components
    systems = Enum.filter(systems, valid_condition?(entity, changes))
    |> Enum.filter(discard_non_reactive_on_updated(changes))
    Logger.debug(inspect({"consumer, filtered systems: ", systems}))
    new_entity = Entity.apply_changes(entity, changes)
    Enum.each(systems, fn system_mod ->
      if Aspect.is_reactive(system_mod.aspect()) do
       system_mod.process(new_entity, changes)
      else
        Enum.each(fields_not_empty(changes), fn change_type ->
          case change_type do
            :attached ->
              send(state.ticker, {:start_tick, entity.id, system_mod})
            :updated ->
              case system_mod.aspect().trigger_condition do
                [every: t, for: _] when is_number(t) ->
                  Process.send_after(state.ticker, {:tick, entity.id, system_mod}, t)
                _ ->
                  send(state.ticker, {:tick, entity.id, system_mod})
              end
            :removed ->
              send(state.ticker, {:stop_tick, entity.id, system_mod})
          end
        end)
      end
    end)
    {:noreply, [], state}
  end

  def valid_components?(changes) do
    components_detected = reduce_changes(changes)
#    Logger.debug(inspect({"changes in these components: ", components_detected}, pretty: true))
    fn system ->
      match_with_condition =
      Enum.all?(system.aspect().with, fn component ->
#        Logger.debug(inspect({"is this component", component, "in?", system}, pretty: true))
        Enum.any?(components_detected, fn c -> component == c end)
#        Logger.debug(inspect(b, pretty: true))
      end)
#      Logger.debug(inspect({"match this system with cond", system, "?", match_with_condition}, pretty: true))

      match_without_condition =
      system.aspect().without == [] ||
      (Enum.any?(system.aspect().without, fn component ->
        Enum.any?(components_detected, fn c -> component == c end)
      end))
      |> Kernel.&&(match_with_condition)
#      Logger.debug(inspect({"match this system without cond", system, "?", match_without_condition}, pretty: true))
#      match_without_condition
    end
  end

  defp reduce_changes(changes) do
    changes.attached ++ changes.updated ++ changes.removed
    |> Enum.map(fn c -> c.type end)
    |> MapSet.new()
  end

  defp valid_condition?(entity, changes) do
    fn system_m ->
      case {Map.get(system_m.aspect(), :trigger_condition, nil)} do
        {[every: _period, for: :stopped], _} -> false
        {[every: _period, for: 0], _} -> false
        {[every: _period, for: ticks_left], cause} ->
          Logger.debug(inspect({system_m, "is a valid non-reactive system"}))
          system_m == cause
        [fun: fun, lifecycle: lifecycle] ->
          detect_changes_type(changes, lifecycle) &&
          fun.(system_m, entity, changes)
        _ -> false
      end
    end
  end

  #this filter
  defp discard_non_reactive_on_updated(changes) do
    fn system_m ->

    end
  end

  defp detect_changes_type(changes, lifecycle) do
    [:attached, :updated, :removed]
    |> Enum.reduce(MapSet.new(), fn type, set ->
      detect_changes_type(set, changes, type)
    end)
    |> MapSet.intersection(MapSet.new([lifecycle]))
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
    %Changes{attached: new_changes.attached, updated: changes_updated, removed: new_changes.removed}
  end
end

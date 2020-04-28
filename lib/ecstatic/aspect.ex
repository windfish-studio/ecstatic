defmodule Ecstatic.Aspect do
  #Aspect defines whether the calling system should run. Here, we define for which entities or components
  #at which condition, how many times or with how many frequency

  defstruct [
    with: [],
    without: [],
    when: [every: :continuous, for: 1]
  ]

  defmacro __using__(_options) do
    quote do
      @type timer_specs :: [every: number | :continuous,
                             for: timeout()] #todo: is 0 or :stopped allowed?
      @type react_specs :: fun()            #todo: define better this function
      @type t :: %Ecstatic.Aspect{
                   with: [atom()],
                   without: [atom()],
                   when: react_specs() | timer_specs()
                 }

      @spec new(with: [Ecstatic.Component.t()], without: [Ecstatic.Component.t()], when: timer_specs) :: t()
      def new(with: with_components, without: without_components, when: cond)
          when is_list(without_components)
               when is_list(with_components) do
        %Ecstatic.Aspect{
          with: with_components,
          without: without_components,
          when: cond
        }
      end

      defguard is_tick(ticks) when (is_number(ticks) and ticks > 0) or ticks == :infinity
      defguard is_interval(interval) when (is_number(interval) and interval > 0) or interval == :continuous

      def watcher_should_trigger?(entity, changes) do
        fn watcher ->
          cond do
            Map.get(watcher, :ticker, nil) != nil -> true
            Map.get(watcher, :callback, nil) != nil ->
              watcher.callback.(
                               entity,
                               Enum.find(
                                 Map.get(changes, watcher.component_lifecycle_hook),
                                 fn component -> watcher.component == component.type end
                               )
                               )
          end
        end
      end

      def with(aspect) do
        aspect.with
      end
    end
  end
end

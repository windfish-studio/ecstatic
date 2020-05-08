# Ecstatic

ECStatic is an Entity-Component-Systems framework in Elixir.

# Getting Started

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecstatic` to your list of dependencies in `mix.exs`:

```
def deps do
  [{:ecstatic, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ecstatic](https://hexdocs.pm/ecstatic).

# Vocabulary
Here's a list of Ecstatic words; following will be an example sentence in English where we can connect each word to something meaningful for you.
- `Ecstatic.Component` : a collection of properties and specific methods
- `Ecstatic.Entity` : a collection of components
- `Ecstatic.Aspect` : a filter for entities, based on which components are and aren't on that entity. The user can also specify running conditions.
- `Ecstatic.System` : business logic; receives an entity and will do some work on it if the entity matches a given aspect. What the system do is defined its the dispatch
- `Ecstatic.Changes` : a collection of components that had been `:attached`, `:removed` or `:updated`.

So if Zaphod is a 33-year-old alien who doesn't have tendonitis and plays tennis, then his stamina will go down but he won't hurt after the game.

This could be written as (for example):
There's an entity that has a "social component" with a name of "Zaphod", a "race component" with a name of "alien", and who does not have the "tendonitis component". When taken through the TennisGame "system", the entity's "physical component" will see its stamina reduced. An "aspect" will check for "physical components" with a stamina going down and pass those to a HealthSystem; if the entity matches the "aspect" of "has tendonitis component", it will add a "pain component" to the entity.

# Usage

## Entity and Components

Let's set the following example. Imagine that we have humans. They can get old and die, so let's add them Age and Mortal components:
```
  defmodule Human do
    use Ecstatic.Entity
    @default_components [Age, Mortal]
  end
```

The entity Human have been just defined. Now, we have to define its components:

```
  defmodule Age do
    use Ecstatic.Component
    @default_state %{age: 0, life_expectancy: 80}
  end
```

```
  defmodule Mortal do
    use Ecstatic.Component
    @default_state %{mortal: true}
  end
```

When we create a new human, by default, they will be 0 years old, mortal, with a life_expectancy of 80 years.

## System

The system the most important module, it defines when and what to do with the entities
A system has to be defined in two parts: the aspect and the dispatch. Let's make out humans age and die.
```
    defmodule PopulateSystem do

    def aspect, do: %Ecstatic.Aspect{} #this is the default aspect

    def dispatch(_entity, _changes, _delta) do
        Ecstatic.Changes{} #dispatch must reply this structure
    end
```

Now, we have to define aspect\0 and dispatch\3
### Aspect
Please, check **Ecstatic.Aspect** documentation for more examples.

### Dispatch
  ```
  defmodule AgeSystem do
    use Ecstatic.System

    def aspect, do: %Ecstatic.Aspect{with: [Age], trigger_condition: [every: 1000, for: :infinity]}
    #1000 msec -> 1 year

    def dispatch(entity) do
      age_comp = Entity.find_component(entity, Age)
      new_age_comp = %{age_comp | age: age_comp.age + 1}
      %Ecstatic.Changes{updated: [new_age_comp]}
    end
  end
    ```
    
  defmodule DeathOfOldAgeSystem do
    use Ecstatic.System

    def aspect, do: %Ecstatic.Aspect{with: [Age, Mortal], trigger_condition: [lifecycle: :updated,
        condition: fn (_entity, changes, _delta) ->
            age_component = changes.updated
            age_component.age > age_component.life_expectancy &&
            Enum.rand(10_000) > 7000
        end]}

    def dispatch(entity) do
        %Ecstatic.Changes{attached: [Dead]}
    end
  end
```

### Usage
Returning to our tiny world. We could define the Populate system as timed one, that creates a human every second:
```
    defmodule PopulateSystem do

    def aspect, do: %Ecstatic.Aspect{with:[]} #this is the default aspect

    def dispatch(_entity, _changes, _delta) do
        Ecstatic.Changes{} #dispatch must reply this structure
    end
```

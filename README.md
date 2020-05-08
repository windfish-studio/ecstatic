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
    defmodule AgeSystem do
        use Ecstatic.System
        def aspect, do: %Ecstatic.Aspect{}  #this is the default aspect
    
        def dispatch(_entity, _changes, _delta) do
            Ecstatic.Changes{}              #dispatch must reply this structure
    end
    
    defmodule DeathOfOldAgeSystem do
        use Ecstatic.System
        def aspect, do: %Ecstatic.Aspect{}  #this is the default aspect
    
        def dispatch(_entity, _changes, _delta) do
            Ecstatic.Changes{}              #dispatch must reply this structure
    end
```

Now, we have to define aspect\0 and dispatch\3 for both systems.

### Aspect
Let's say that 10 seconds in real life are one year in the simulation. Also, to stay simple, only entities that are going to age are those with Age component. 
```
defmodule AgeSystem do
    use Ecstatic.System
    def aspect, do: %Ecstatic.Aspect{with: [Age], trigger_condition: [every: 10000, for: :infinity]}
end
``` 

Now, let's kill the elders!
```
defmodule DeathOfOldAgeSystem do
    use Ecstatic.System
    def aspect, do: %Ecstatic.Aspect{with: [Age], trigger_condition: [lifecycle: [:updated], 
    condition: fn (_cause_systems, entity, _changes) -> 
        age_component = Entity.find_component(entity, Age)
        age = age_component.state.age
        life_expectancy = age_component.state.life_expectancy
        age >= life_expectancy 
    end]}
end
```

Please, check **Ecstatic.Aspect** documentation for more examples.

### Dispatch
We had defined when our systems should act in its aspect. Now, let's define what these systems are doing.

```
  defmodule AgeSystem do
  use Ecstatic.System
    def dispatch(entity, _changes) do
      age_comp = Entity.find_component(entity, Age)
      new_age_comp = %{age_comp | age: age_comp.age + 1}
      %Ecstatic.Changes{updated: [new_age_comp]}
    end
  end
```

```
  defmodule DeathOfOldAgeSystem do
  use Ecstatic.System
    def dispatch(entity) do
        %Ecstatic.Changes{attached: [Dead]}
    end
  end
```

Notice, that we have to create a implement the 'Dead' component.

## Entity's lifecycle
Where are our humans? There's nobody around. That is because we have not created any human yet. In order to do so, let's define an init function in our main process (is up to you).
```
def initialization() do

end
```

# Crap that shouldn't be here


3) Todas las formas que el usuario puede usar el dispatch/2 para modificar el entity, o para modificar/borrar/añadir otros entities; 
explicando bien los parametros que lleguen al dispatch/2
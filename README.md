delegate_behaviour
=================

Elixir macros to define modules that delegate to concrete implementations of behaviours.
Useful to select specific implementation of behaviour in a pluggable way, like dependency injection.

- [Hex package information](https://hex.pm/packages/delegate_behaviour)

[![Hex.pm](http://img.shields.io/hexpm/v/delegate_behaviour.svg)](https://hex.pm/packages/delegate_behaviour)
[![Hex.pm](http://img.shields.io/hexpm/dt/delegate_behaviour.svg)](https://hex.pm/packages/delegate_behaviour)
[![Build Status](https://travis-ci.org/skirino/delegate_behaviour.svg)](https://travis-ci.org/skirino/delegate_behaviour)
[![Coverage Status](https://coveralls.io/repos/skirino/delegate_behaviour/badge.png?branch=master)](https://coveralls.io/r/skirino/delegate_behaviour?branch=master)
[![Github Issues](http://githubbadges.herokuapp.com/skirino/delegate_behaviour/issues.svg)](https://github.com/skirino/delegate_behaviour/issues)
[![Pending Pull-Requests](http://githubbadges.herokuapp.com/skirino/delegate_behaviour/pulls.svg)](https://github.com/skirino/delegate_behaviour/pulls)

## Installation

- Add `:delegate_behaviour` as a mix dependency.
- `$ mix deps.get`

## Usage example

Suppose you have a behaviour and two modules that implement the behaviour.

```ex
iex> defmodule B do
...>   use Behaviour
...>   @callback f(integer) :: integer
...> end
iex> defmodule Impl1 do
...>   @behaviour B
...>   def f(i), do: i + 1
...> end
iex> defmodule Impl2 do
...>   @behaviour B
...>   def f(i), do: i + 2
...> end
```

Now you can easily define a module that implements the behaviour `B`
by delegating all behaviour functions to the module `Impl1` or `Impl2`.
There are two variants of delegations:

- Choosing target implementation at compile-time

    ```ex
    iex> defmodule C do
    ...>   require DelegateBehaviour
    ...>   DelegateBehaviour.compile_time(B) do
    ...>     # Put code block to choose the target module;
    ...>     # do whatever you like to determine which module you delegate to,
    ...>     # e.g. environment variable, application config, config file, etc.
    ...>     # The code block is evaluated at compile time.
    ...>     case System.get_env("SOME_ENV_VAR") do
    ...>       "Impl1" -> Impl1
    ...>       _       -> Impl2
    ...>     end
    ...>   end
    ...> end
    iex> C.f(0)
    2
    ```

- Choosing target implementation at runtime

    ```ex
    iex> defmodule R do
    ...>   require DelegateBehaviour
    ...>   DelegateBehaviour.runtime(B) do
    ...>     # Put code block to choose the target module;
    ...>     # do whatever you like to determine which module you delegate to,
    ...>     # e.g. environment variable, application config, config file, etc.
    ...>     # The code block is evaluated at each invocation of the behaviour functions.
    ...>     case System.get_env("SOME_ENV_VAR") do
    ...>       "Impl1" -> Impl1
    ...>       _       -> Impl2
    ...>     end
    ...>   end
    ...> end
    iex> R.f(0)
    2
    ```

All behaviour interface functions are generated as delegations, together with their type specifications.

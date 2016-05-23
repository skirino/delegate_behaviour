defmodule DelegateBehaviour do
  defmacro compile_time(behaviour, arg) do
    impl_module =
      case arg do
        [do: block] ->
          {mod, _bindings} = Code.eval_quoted(block, [], __CALLER__)
          mod
        module_alias -> module_alias
      end
    quote bind_quoted: [behaviour: behaviour, impl_module: impl_module] do
      @behaviour behaviour
      for callback <- DelegateBehaviour.callbacks(behaviour) do
        {name, arity, {arg_types, ret_type}, constraints} = DelegateBehaviour.analyze_callback(behaviour, callback)
        vars = DelegateBehaviour.make_vars(arity, __MODULE__)
        if Enum.empty?(constraints) do
          @spec unquote(name)(unquote_splicing(arg_types)) :: unquote(ret_type)
        else
          @spec unquote(name)(unquote_splicing(arg_types)) :: unquote(ret_type) when [unquote_splicing(constraints)]
        end
        defdelegate unquote(name)(unquote_splicing(vars)), to: impl_module
      end
    end
  end

  defmacro runtime(behaviour, do: block) do
    quote bind_quoted: [behaviour: behaviour, block: block] do
      @behaviour behaviour

      defp _delegate_behaviour_module_switcher do
        unquote(block)
      end

      for callback <- DelegateBehaviour.callbacks(behaviour) do
        {name, arity, {arg_types, ret_type}, constraints} = DelegateBehaviour.analyze_callback(behaviour, callback)
        vars = DelegateBehaviour.make_vars(arity, __MODULE__)
        if Enum.empty?(constraints) do
          @spec unquote(name)(unquote_splicing(arg_types)) :: unquote(ret_type)
        else
          @spec unquote(name)(unquote_splicing(arg_types)) :: unquote(ret_type) when [unquote_splicing(constraints)]
        end
        def unquote(name)(unquote_splicing(vars)) do
          _delegate_behaviour_module_switcher.unquote(name)(unquote_splicing(vars))
        end
      end
    end
  end

  @doc false
  def make_vars(n, module) do
    if n == 0 do
      []
    else
      Enum.map(0 .. n-1, fn i -> Macro.var(String.to_atom("arg#{i}"), module) end)
    end
  end

  @doc false
  def callbacks(behaviour) do
    behaviour.module_info(:attributes)
    |> Enum.filter_map(fn {k, _} -> k == :callback end, fn {_, v} -> v end)
  end

  @doc false
  def analyze_callback(behaviour, callback) do
    case callback do
      [{{name, arity}, [{:type, _, :bounded_fun, [f, constraints]}]}] -> {name, arity, args_ret_type_pair(behaviour, f), Enum.map(constraints, &analyze_constraint(behaviour, &1))}
      [{{name, arity}, [f]}]                                          -> {name, arity, args_ret_type_pair(behaviour, f), []}
    end
  end

  defp args_ret_type_pair(behaviour, {:type, _, :fun, [{:type, _, :product, args}, ret]}) do
    {types_of(behaviour, args), type_of(behaviour, ret)}
  end

  defp analyze_constraint(behaviour, {:type, _, :constraint, [{:atom, _, :is_subtype}, [{:var, _, type_param_name}, t]]}) do
    {type_param_name, type_of(behaviour, t)}
  end

  defp type_of(behaviour, tuple) do
    case tuple do
      {:atom, _, a}                                             -> a
      {:integer, _, n}                                          -> n
      {:var, _, n}                                              -> Macro.var(n, Elixir)
      {:ann_type, _, [{:var, _, _}, t]}                         -> type_of(behaviour, t)
      {:remote_type, _, [{:atom, _, m}, {:atom, _, n}, types]}  -> quote do: unquote(m).unquote(n)(unquote_splicing(types_of(behaviour, types)))
      {:user_type, _, t, type_params}                           -> quote do: unquote(behaviour).unquote(t)(unquote_splicing(types_of(behaviour, type_params)))
      {:type, _, :binary, [{:integer, _, i}, {:integer, _, j}]} -> bitstring_type(i, j)
      {:type, _, :list, types}                                  -> quote do: [unquote_splicing(types_of(behaviour, types))]
      {:type, _, :tuple, :any}                                  -> quote do: tuple()
      {:type, _, :tuple, types}                                 -> quote do: {unquote_splicing(types_of(behaviour, types))}
      {:type, _, :map, :any}                                    -> quote do: %{}
      {:type, _, :map, []}                                      -> quote do: %{}
      {:type, _, :map, [{:type, _, :map_field_assoc, [k, v]}]}  -> quote do: %{unquote(type_of(behaviour, k)) => unquote(type_of(behaviour, v))}
      {:type, _, :fun, [{:type, _, :any}, r]}                   -> quote do: (... -> unquote(type_of(behaviour, r)))
      {:type, _, :fun, [{:type, _, :product, types}, r]}        -> quote do: ((unquote_splicing(types_of(behaviour, types))) -> unquote(type_of(behaviour, r)))
      {:type, _, :union, types}                                 -> union_type(types_of(behaviour, types))
      {:type, _, :range, [{:integer, _, l}, {:integer, _, u}]}  -> quote do: unquote(l) .. unquote(u)
      {:type, _, t, types}                                      -> quote do: unquote(t)(unquote_splicing(types_of(behaviour, types)))
    end
  end

  defp types_of(behaviour, tuples) do
    Enum.map(tuples, &type_of(behaviour, &1))
  end

  defp bitstring_type(0, 0) do
    quote do: <<>>
  end
  defp bitstring_type(i, 0) do
    quote do: <<_ :: unquote(i)>>
  end
  defp bitstring_type(0, j) do
    quote do: <<_ :: _ * unquote(j)>>
  end

  defp union_type(types) do
    case types do
      [t1, t2] -> quote do: unquote(t1) | unquote(t2)
      [h | t]  -> quote do: unquote(h) | unquote(union_type(t))
    end
  end
end

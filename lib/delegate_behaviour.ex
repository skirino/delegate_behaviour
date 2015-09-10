defmodule DelegateBehaviour do
  defmacro compile_time(behaviour, do: block) do
    {impl_module, _bindings} = Code.eval_quoted(block, [], __CALLER__)
    quote bind_quoted: [behaviour: behaviour, impl_module: impl_module] do
      @behaviour behaviour
      for callback <- DelegateBehaviour.callbacks(behaviour) do
        {name, arity, arg_types, ret_type} = DelegateBehaviour.analyze_callback(callback)
        vars = DelegateBehaviour.make_vars(arity, __MODULE__)
        @spec unquote(name)(unquote_splicing(arg_types)) :: unquote(ret_type)
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
        {name, arity, arg_types, ret_type} = DelegateBehaviour.analyze_callback(callback)
        vars = DelegateBehaviour.make_vars(arity, __MODULE__)
        @spec unquote(name)(unquote_splicing(arg_types)) :: unquote(ret_type)
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
      Enum.map(0 .. n-1, fn i -> Macro.var(String.to_atom("a#{i}"), module) end)
    end
  end

  @doc false
  def callbacks(behaviour) do
    behaviour.module_info(:attributes)
    |> Enum.filter_map(fn {k, _} -> k == :callback end, fn {_, v} -> v end)
  end

  @doc false
  def analyze_callback(callback) do
    [{{name, arity}, [{:type, _, :fun, [{:type, _, :product, args}, ret]}]}] = callback
    {name, arity, types_of(args), type_of(ret)}
  end

  defp type_of(tuple) do
    case tuple do
      {:ann_type, _, [{:var, _, _}, t]}                         -> type_of(t)
      {:remote_type, _, [{:atom, _, m}, {:atom, _, n}, types]}  -> quote do: unquote(m).unquote(n)(unquote_splicing(types_of(types)))
      {:type, _, :binary, [{:integer, _, i}, {:integer, _, j}]} -> bitstring_type(i, j)
      {:type, _, :list, types}                                  -> quote do: [unquote_splicing(types_of(types))]
      {:type, _, :tuple, :any}                                  -> quote do: tuple()
      {:type, _, :tuple, types}                                 -> quote do: {unquote_splicing(types_of(types))}
      {:type, _, :map, []}                                      -> quote do: %{}
      {:type, _, :map, [{:type, _, :map_field_assoc, [k, v]}]}  -> quote do: %{unquote(type_of(k)) => unquote(type_of(v))}
      {:type, _, :fun, [{:type, _, :any}, r]}                   -> quote do: (... -> unquote(type_of(r)))
      {:type, _, :fun, [{:type, _, :product, types}, r]}        -> quote do: ((unquote_splicing(types_of(types))) -> unquote(type_of(r)))
      {:type, _, t, types}                                      -> quote do: unquote(t)(unquote_splicing(types_of(types)))
    end
  end

  defp types_of(tuples) do
    Enum.map(tuples, &type_of/1)
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
end

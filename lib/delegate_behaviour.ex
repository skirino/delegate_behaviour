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
    arg_types = Enum.map(args, &type_of/1)
    ret_type  = type_of(ret)
    {name, arity, arg_types, ret_type}
  end

  defp type_of(tuple) do
    case tuple do
      {:ann_type, _, [{:var, _, _}, t]}                             -> type_of(t)
      {:type, _, t, _}                                              -> Macro.var(t, Elixir)
      {:remote_type, _, [{:atom, _, module}, {:atom, _, name}, []]} -> quote do: unquote(module).unquote(name)
    end
  end
end

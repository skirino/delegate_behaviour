require DelegateBehaviour

defmodule DelegateBehaviourTest do
  use ExUnit.Case

  defmodule B do
    use Behaviour
    defcallback i :: integer
    defcallback s(s1 :: String.t, String.t) :: String.t
    defcallback b(<<_ :: _ * 8>>) :: <<>>
    defcallback l([integer]) :: list
    defcallback k(Keyword.t(integer)) :: Keyword.t(integer)
    defcallback t({atom, integer}) :: tuple
    defcallback m(%{atom => String.t}, map) :: %{}
    defcallback f((atom, String.t -> String.t)) :: (... -> String.t)
    defcallback u(:atom1 | :atom2 | String.t) :: :ok
    defcallback r(0..10) :: 0
    defcallback w(a, b, c) :: a when a: String.t, b: (() -> String.t), c: %{atom => String.t}
  end

  defmodule I do
    @behaviour B
    def i, do: 0
    def s(s1, s2), do: "I.s: #{s1} #{s2}"
    def b(v), do: v
    def l(v), do: v
    def k(v), do: v
    def t(v), do: v
    def m(v, _v2), do: v
    def f(v), do: v
    def u(_v), do: :ok
    def r(_r), do: 0
    def w(a, _b, _c), do: a
  end

  defmodule CT1 do
    DelegateBehaviour.compile_time(B) do
      I
    end

    spec = Module.get_attribute(__MODULE__, :spec) |> Macro.escape
    def typespecs, do: unquote(spec) |> Enum.map(fn {:spec, expr, _} -> Macro.to_string(expr) end)
  end

  defmodule CT2 do
    DelegateBehaviour.compile_time(B, I)

    spec = Module.get_attribute(__MODULE__, :spec) |> Macro.escape
    def typespecs, do: unquote(spec) |> Enum.map(fn {:spec, expr, _} -> Macro.to_string(expr) end)
  end

  defmodule RT do
    DelegateBehaviour.runtime(B) do
      I
    end

    spec = Module.get_attribute(__MODULE__, :spec) |> Macro.escape
    def typespecs, do: unquote(spec) |> Enum.map(fn {:spec, expr, _} -> Macro.to_string(expr) end)
  end

  defp runtest(module) do
    f = fn a, s -> (fn -> "#{a} #{s}" end) end

    assert module.i                         == 0
    assert module.s("a", "b")               == "I.s: a b"
    assert module.b(<<>>)                   == <<>>
    assert module.l([])                     == []
    assert module.k([])                     == []
    assert module.t({:a, 0})                == {:a, 0}
    assert module.m(%{a: "a"}, %{})         == %{a: "a"}
    assert module.f(f)                      == f
    assert module.u(:atom1)                 == :ok
    assert module.r(3..5)                   == 0
    assert module.w("a", fn -> "" end, %{}) == "a"

    assert "i() :: integer()"                                                                      in module.typespecs
    assert "s(String.t(), String.t()) :: String.t()"                                               in module.typespecs
    assert "b(<<_::_ * 8>>) :: <<>>"                                                               in module.typespecs
    assert "l([integer()]) :: []"                                                                  in module.typespecs
    assert "k(Keyword.t(integer())) :: Keyword.t(integer())"                                       in module.typespecs
    assert "t({atom(), integer()}) :: tuple()"                                                     in module.typespecs
    assert "m(%{atom() => String.t()}, %{}) :: %{}"                                                in module.typespecs
    assert "f((atom(), String.t() -> String.t())) :: (... -> String.t())"                          in module.typespecs
    assert "u(:atom1 | :atom2 | String.t()) :: :ok"                                                in module.typespecs
    assert "r(0..10) :: 0"                                                                         in module.typespecs
    assert "w(a, b, c) :: a when a: String.t(), b: (() -> String.t()), c: %{atom() => String.t()}" in module.typespecs
  end

  test "CT1/CT2 should delegate to I" do
    runtest(CT1)
    runtest(CT2)
  end

  test "RT should delegate to I" do
    runtest(RT)
  end
end

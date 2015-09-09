require DelegateBehaviour

defmodule DelegateBehaviourTest do
  use ExUnit.Case

  defmodule B do
    use Behaviour
    defcallback f :: integer
    defcallback g(s1 :: String.t, String.t) :: String.t
  end

  defmodule I do
    @behaviour B
    def f, do: 0
    def g(s1, s2), do: "I.g: #{s1} #{s2}"
  end

  defmodule CT do
    DelegateBehaviour.compile_time(B) do
      I
    end

    spec = Module.get_attribute(__MODULE__, :spec) |> Macro.escape
    def typespecs, do: unquote(spec) |> Enum.map(fn {:spec, expr, _} -> Macro.to_string(expr) end)
  end

  test "CT should delegate to I" do
    assert CT.f                                      == 0
    assert CT.g("a", "b")                            == "I.g: a b"
    assert "f() :: integer"                          in CT.typespecs
    assert "g(String.t(), String.t()) :: String.t()" in CT.typespecs
  end

  defmodule RT do
    DelegateBehaviour.runtime(B) do
      I
    end

    spec = Module.get_attribute(__MODULE__, :spec) |> Macro.escape
    def typespecs, do: unquote(spec) |> Enum.map(fn {:spec, expr, _} -> Macro.to_string(expr) end)
  end

  test "RT should delegate to I" do
    assert RT.f                                      == 0
    assert RT.g("a", "b")                            == "I.g: a b"
    assert "f() :: integer"                          in RT.typespecs
    assert "g(String.t(), String.t()) :: String.t()" in RT.typespecs
  end
end

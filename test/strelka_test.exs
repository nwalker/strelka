defmodule StrelkaTest do
  use ExUnit.Case
  alias Strelka, as: S

  test "simple" do
    r = S.router([
      ["/api",
        ["/ipa", %{test: true},
          ["/:size", :beer]]]
    ])
    assert [
      {"/api/ipa/:size", %{test: true, name: :beer}}
    ] = S.routes(r)

    assert [:beer] == S.route_names(r)
  end

  test "simple2" do
    r = S.router([
      ["/items", %{test: true},
        ["", %{test: false, name: :list}],
        ["/:id", :item]],
      ["/items/:id/:side", :deep],
    ])
    assert [
      {"/items", %{name: :list, test: false}},
      {"/items/:id", %{name: :item, test: true}},
      {"/items/:id/:side", %{name: :deep}},
    ] = S.routes(r)
    assert [:list, :item, :deep] = S.route_names(r)

  end

  test "nil routes are stripped" do
    [ nil,
      [nil, ["/ping"]],
      [nil, [nil], [[nil, nil, nil]]],
      ["/ping", [nil, "/pong"]],
    ] |> Enum.each(fn r ->
      assert [] = S.routes(S.router(r))
    end)
  end
end

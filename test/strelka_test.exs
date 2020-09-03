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

    assert struct(S.Match,
      template: "/api/ipa/:size",
      data: %{name: :beer, test: true},
      path: "/api/ipa/large",
      path_params: %{size: "large"}
    ) == S.match_path(r, "/api/ipa/large")

    assert struct(S.PartialMatch,
      template: "/api/ipa/:size",
      data: %{name: :beer, test: true},
      path_params: %{},
      required: MapSet.new([:size])
    ) == S.match_name(r, :beer)

    assert struct(S.Match,
      template: "/api/ipa/:size",
      data: %{name: :beer, test: true},
      path: "/api/ipa/large",
      path_params: %{size: "large"}
    ) == S.match_name(r, :beer, size: "large")
  end

  # test "simple2" do
  #   r = S.router([
  #     ["/items", %{test: true},
  #       ["", %{test: false, name: :list}],
  #       ["/:id", :item]],
  #     ["/items/:id/:side", :deep],
  #   ])
  #   assert [
  #     {"/items", %{name: :list, test: false}},
  #     {"/items/:id", %{name: :item, test: true}},
  #     {"/items/:id/:side", %{name: :deep}},
  #   ] = S.routes(r)
  #   assert [:list, :item, :deep] = S.route_names(r)

  #   assert struct(S.PartialMatch,
  #     template: "/items/:id/:side",
  #     data: %{name: :deep},
  #     path_params: %{id: 1},
  #     required: MapSet.new([:side])
  #   ) == S.match_name(r, :deep, id: 1)
  # end

  test "complex" do
    r = S.router([
      ["/:abba", :abba],
      ["/abba/1", :abba2],
      ["/:jabba/2", :jabba2],
      ["/:abba/:dabba/doo", :doo],
      ["/abba/dabba/boo/baa", :baa],
      ["/abba/:dabba/boo", :boo],
      ["/:jabba/:dabba/:doo/:daa/*foo", :wild],
    ]) # |> IO.inspect
    by_path = fn p ->
      case S.match_path(r, p) do
        %{data: %{name: name}, path_params: bound} ->
          # IO.inspect([p, bound])
          name
        _ -> nil
      end
    end

    assert :abba == by_path.("/abba")
    assert :abba2 == by_path.("/abba/1")
    assert :jabba2 == by_path.("/abba/2")
    assert :doo == by_path.("/abba/1/doo")
    assert :boo == by_path.("/abba/1/boo")
    assert :baa == by_path.("/abba/dabba/boo/baa")
    assert :boo == by_path.("/abba/dabba/boo")
    assert :wild == by_path.("/olipa/kerran/avaruus/vaan/")
    assert :wild == by_path.("/olipa/kerran/avaruus/vaan/ei/toista/kertaa")
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

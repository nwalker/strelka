defmodule Strelka.SimpleRouter do
  alias Strelka.Impl

  defmodule PTree do
    # trie like path matcher
    defstruct [statics: %{}, wilds: [], catch_all: nil, data: nil]

    def place(%__MODULE__{statics: s, wilds: w} = root, path, data) do
      case path do
        [] -> %{root | data: data}
        [{:catch, _} = m | rest] = wild ->
          w = [ {m, place(%__MODULE__{}, rest, data)} | w]
          %{root | wilds: w}
        [{:catch_all, name} | _] ->
          %{root | catch_all: {name, data}}
        [pp | rest] when is_binary(pp) ->
          {_, s} = Map.get_and_update(s, pp, fn node ->
            {node, place(node || %__MODULE__{}, rest, data)}
          end)
          %{root | statics: s}
      end
    end

    def build(paths) do
      paths
      |> Enum.reverse()
      |> Enum.reduce(%__MODULE__{}, fn({p, t, m}, acc) -> place(acc, p, {t, m}) end)
    end

    def match(tree, path), do: match(tree, %{}, path)

    def match(%{} = node, bindings, []) do
      # IO.inspect(node, label: :end)
      cond do
        node.catch_all ->
          # catch_all MUST catch empty path tail
          {name, data} = node.catch_all
          {Map.put_new(bindings, name, []), data}
        node.data ->
          # non-empty leaf found
          {bindings, node.data}
        true ->
          # nothing found
          nil
      end
    end

    def match(%__MODULE__{} = node, %{} = bindings, [pp | path] = remaining) do
      # 1 - try static branches
      case Map.get(node.statics, pp) do
        %{} = branch ->
          # IO.inspect([pp, branch], label: :static)
          match(branch, bindings, path)
        nil -> nil
      end || Enum.reduce_while(node.wilds, nil, fn
        # 2 - try ordinary catch branches
        {{:catch, name}, branch}, nil ->
          # IO.inspect([path, {name, pp}, branch], label: :try_wild)
          case match(branch, Map.put_new(bindings, name, pp), path) do
            nil -> {:cont, nil}
            other -> {:halt, other}
          end
      end) || case node.catch_all do
        # 3 - check catch_all branch
        nil -> nil
        {name, data} ->
          # IO.inspect([{name, remaining}], label: :catch_all)
          {Map.put_new(bindings, name, remaining), data}
      end
    end
  end

  defmodule LTree do
    # simple list-based path matcher
    # order-sensitive! catch-all routes should come last
    def build(paths) do
      Enum.map(paths, fn {p, t, m} -> {p, {t, m}} end)
    end

    def match([], _), do: nil
    def match(tree, path) do
      Enum.reduce_while(tree, nil, fn ({p, data}, _) ->
        case match_one(p, %{}, path) do
          nil -> {:cont, nil}
          %{} = bindings -> {:halt, {bindings, data}}
        end
      end)
    end

    # match_one(pattern, bindings, path)

    # successfull termination, pattern MUST end with path
    def match_one([], bindings, []), do: bindings

    # catch_all consumes all remaining path
    def match_one([{:catch_all, name} | _], bindings, remaining), do: Map.put_new(bindings, name, remaining)

    # consume single fragment
    def match_one([{:catch, name} | ttail], bindings, [pp | ptail]), do: match_one(ttail, Map.put_new(bindings, name, pp), ptail)

    # consume static fragment
    def match_one([pp | ttail], bindings, [pp | ptail]), do: match_one(ttail, bindings, ptail)

    # any other case leads to fail
    def match_one(_, _, _), do: nil
  end


  defstruct [:routes, :names, :opts, :tree, :by_name]

  def new(compiled_routes, opts) do
    routes = Impl.uncompile_routes(compiled_routes)
    parsed = Enum.map(routes, fn {r, m} -> {parse(r), r, m} end)
    by_name = Enum.map(parsed, fn {parsed, r, m} ->
      {m[:name], fn args -> unparse(r, m, parsed, args) end}
    end)
    |> Enum.reject(&is_nil(elem(&1, 0)))
    |> Enum.into(%{})
    tree = {PTree, PTree.build(parsed)}
    struct(__MODULE__, [
      routes: routes,
      lookup: parsed,
      names: Impl.find_names(compiled_routes),
      tree: tree,
      by_name: by_name,
      opts: opts,
    ])
  end

  def unparse(template, meta, parsed, args) do
    # IO.inspect([template, meta, parsed, args], label: :unparse)
    {required, replaced, path_params} = Enum.reduce(parsed, {MapSet.new(), [], %{}},
      fn
        ({_, name}), {rq, re, pp} ->
          case args[name] do
            nil -> {MapSet.put(rq, name), [nil | re], pp}
            v -> {rq, [to_string(v) | re], Map.put(pp, name, v)}
          end
        (s, {rq, re, pp}) -> {rq, [s | re], pp}
      end)
    cond do
      MapSet.size(required) == 0 ->
        path_parts = Enum.reverse(replaced)
        struct(Strelka.Match, [
          template: template,
          data: meta,
          path: Enum.join(["" | path_parts], "/"),
          path_params: path_params,
        ])
      true ->
        struct(Strelka.PartialMatch, [
          template: template,
          data: meta,
          path_params: path_params,
          required: required,
        ])
    end
  end

  def parse(r) do
    String.split(r, "/", trim: true)
    |> Enum.map(fn
      # TODO: add prefix support
      ":" <> name -> {:catch, String.to_atom(name)}
      "*" <> name -> {:catch_all, String.to_atom(name)}
      other -> other
    end)
  end

  defimpl Strelka.Router do
    def name(_), do: Strelka.SimpleRouter
    def routes(%{routes: routes}), do: routes
    def route_names(%{names: names}), do: names
    def options(%{opts: opts}), do: opts

    def match_path(%{tree: {mod, t}}, path) do
      case mod.match(t, String.split(path, "/", trim: true)) do
        nil -> nil
        {bindings, {t, m}} ->
          struct(Strelka.Match, [
            template: t,
            data: m,
            path: path,
            path_params: bindings
          ])
      end
    end
    def match_name(%{by_name: ns}, n, params) do
      case ns[n] do
        nil -> nil
        f -> f.(Map.new(params))
      end
    end
  end
end

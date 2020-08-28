defmodule Strelka.Impl do
  def find_names(routes) do
    Stream.map(routes, fn r ->
      elem(r, 1) |> Access.get(:name)
    end)
    |> Enum.reject(&is_nil/1)
  end

  def resolve_routes(routes, opts) do
    walk_routes(routes, opts)
    |> Enum.map(fn {p, m} ->
      {p, merge_meta(m)}
    end)
  end

  def compile_routes(routes, _opts) do
    routes
    |> Stream.map(fn {p, m} ->
      # TODO: use compile handler from opts
      {p, m, m[:handler]}
    end)
    |> Enum.reject(&is_nil/1)
  end

  def uncompile_routes(compiled_routes) do
    Enum.map(compiled_routes, fn {p, m, _} -> {p, m} end)
  end

  def expand(i, _opts) do
    # TODO: use expand handler from opts
    case i do
      a when is_atom(a) -> %{name: a}
      m when is_map(m) -> m
      f when is_function(f) -> %{handler: f}
      {m, f, a} = mfa when is_atom(m) and is_atom(f) and is_list(a) -> %{handler: mfa}
    end
  end

  def merge_meta(m) do
    # TODO: implement meta-merge
    Enum.reverse(m)
    |> Enum.reduce(%{}, fn (x, acc) ->
      Map.merge(acc, x)
    end)
  end

  def walk_routes(raw_routes, opts) do
    root = (opts[:path] || "")
    meta_root = case opts[:data] do
      nil -> []
      other -> [other]
    end
    walk([], root, meta_root, raw_routes, opts) |> Enum.reverse
  end

  def walk(acc, _path, _meta, nil, _opts), do: acc
  def walk(acc, _path, _meta, [nil | _], _opts), do: acc

  def walk(acc, path, meta, [route | _] = node, opts) when is_list(route) do
    Enum.reduce(node, acc, fn r, acc -> walk(acc, path, meta, r, opts) end)
  end

  def walk(acc, path, meta, [pp | tail], opts) when is_binary(pp) do
    {mp, childs} = case tail do
      [] -> {[], []}
      [other | l] when not is_list(other) -> {[expand(other, opts)], l}
      l when is_list(l) -> {[], l}
    end
    case childs do
      [] ->
        [{path<>pp, mp++meta} | acc]
      _ ->
        Enum.reduce(childs, acc, fn r, acc ->
          walk(acc, path<>pp, mp++meta, r, opts)
        end)
    end
  end
end

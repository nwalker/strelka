defmodule Strelka.SimpleRouter do
  alias Strelka.Impl

  defstruct [:routes, :names, :opts, :by_name]

  def new(compiled_routes, opts) do
    routes = Impl.uncompile_routes(compiled_routes)
    struct(__MODULE__, [
      routes: routes,
      names: Impl.find_names(compiled_routes),
      opts: opts,
    ])
  end

  defimpl Strelka.Router do
    def name(_), do: Strelka.SimpleRouter
    def routes(%{routes: routes}), do: routes
    def route_names(%{names: names}), do: names
    def options(%{opts: opts}), do: opts
  end
end

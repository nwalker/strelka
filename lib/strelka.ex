
defmodule Strelka do
  alias Strelka.{Impl, SimpleRouter}

  defprotocol Router do
    def name(router)
    def options(router)
    def routes(router)
    def match_path(router, path)
    def match_name(router, name, params)
    def route_names(router)
  end

  def routes(router) do
    Router.routes(router)
  end

  def route_names(router) do
    Router.route_names(router)
  end

  def match_path(router, path) do
    Router.match_path(router, path)
  end

  def match_name(router, name, path_params \\ %{}) do
    Router.match_name(router, name, path_params)
  end

  def router(routes, opts \\ []) do
    compiled_routes = routes
    |> Impl.resolve_routes(opts)
    |> Impl.compile_routes(opts)
    router = SimpleRouter.new(compiled_routes, opts)
  end
end

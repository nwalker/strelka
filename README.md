# Strelka

**TODO: Add description**

## TODO:
- [x] Router protocol
- [x] simplest protocol implementation possible
- [ ] prefixed path parameters(`"/prefix-:id"`)
- [ ] compile/coerce/expand handlers
- [ ] internal route representation
- [ ] route conflict handling(checking and resolution)
- [ ] cowboy integration or usage example at least
- [ ] plug integration
- [ ] compiled router implementation like Phoenix.Router but without all that magic
- [ ] moar tests

### wet dreams and wild fantasies
- [ ] evaluate proper Trie, instead of path-part tree
- [ ] related to previous - bracket syntax from reitit and slash-free routing
- [ ] evaluate interceptors instead of middlewares
- [ ] property-based tests

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `strelka` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:strelka, git: "https://github.com/nwalker/strelka.git"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/strelka](https://hexdocs.pm/strelka).


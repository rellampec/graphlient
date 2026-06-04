# CLAUDE.md — graphlient (EcoPortal fork)

AI agent instructions for this repository.

**Cross-cutting architecture context lives in `ecoportal-api-graphql` — see its `CLAUDE.md` and `.claude/` folder for the full dependency map, project history, and shared skills.**

---

## Repository Role

This is **EcoPortal's fork** of `graphlient` — a friendly Ruby client wrapper around `graphql-client`. `ecoportal-api-graphql` depends on this fork; `Common::GraphQL::Client` inherits from `Graphlient::Client`.

**Position in chain:**
```
graphql-client (our fork)
      ↓
graphlient             ← THIS REPO (our fork)
      ↓
ecoportal-api-graphql
```

**Our fork:** https://github.com/rellampec/graphlient.git
**Upstream:**  https://github.com/ashkan18/graphlient.git

---

## Fork Policy

- Changes made here are **not automatically contributed upstream**. If a fix is general enough to benefit the upstream project, discuss with the developer before opening a PR upstream.
- When pulling upstream changes, check for conflicts with any local modifications first.
- Keep a note in `CHANGELOG.md` (or a fork-specific section) for any changes that diverge from upstream.

---

## Key Folder Layout

```
lib/graphlient/
  client.rb            Main Graphlient::Client class
  adapters/http/       HTTP adapters — faraday_adapter, http_adapter
  errors/              Error hierarchy (client, server, execution, timeout, etc.)
  extensions/query.rb  Query DSL extension
  query.rb             Query builder
  schema.rb            Schema introspection and caching
```

---

## Namespace

`Graphlient::` — single top-level namespace.

---

## Key Concerns

- `Graphlient::Client` is the class `ecoportal-api-graphql`'s `Common::GraphQL::Client` inherits from. Its constructor signature, `#execute`, and error classes are the primary integration surface.
- `no_schema:` option (added or expected by our usage) — schema introspection is disabled in EcoPortal's GraphQL client. Verify this is handled correctly after any changes to `schema.rb`.
- Error classes are caught and re-raised by `ecoportal-api-graphql` — changes to the error hierarchy may break upstream error handling.

---

## Running Tests

```bash
bundle install
bundle exec rspec
```

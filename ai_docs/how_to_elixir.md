**Elixir Code  — Guidelines**
- Prefer clear, descriptive names over excessive or obvious comments; use @doc/@moduledoc for documentation.
- Handle errors close to their source; avoid large, ambiguous else blocks in with expressions.
- Only extract variables needed for pattern matching or guards in function clauses—extract the rest inside the function.
- Never create atoms dynamically from untrusted input; use String.to_existing_atom/1 or explicit mapping.
- Limit function parameter lists; group related arguments in maps or structs.
- Keep all library modules in their own namespace to prevent naming conflicts.
- Use static map.key access for required keys, dynamic map[:key] only for optional keys; consider pattern matching or structs for key enforcement.
- Write assertive code with explicit pattern matching; avoid defensive code and catch-alls (_).
- Use and/or/not for boolean logic (booleans only), not &&/||/! (which accept any value).
- Avoid structs with 32+ fields; nest related/optional data in sub-structs or fields.

**Elixir Design Guidelines**
- Do **not** use options that change function return types. → Use separate functions for each return type.
- Avoid multiple overlapping boolean flags. → Use a single atom or composite type (e.g., `:role`).
- Do **not** use exceptions for normal control flow. → Prefer `{:ok, result}` / `{:error, reason}` returns; reserve exceptions for true errors.
- Do **not** represent complex concepts with bare primitives (strings, ints, floats). → Model with structs/maps for clarity and maintainability.
- Do **not** group unrelated logic in multi-clause functions. → Split unrelated behaviors into distinct functions/modules.

**Elixir Process-Related - Guidelines**
- **Don’t organize code by processes:** Use processes (GenServer, Agent, etc.) only for concurrency, isolation, or shared state—not just for code structure.
- **Centralize process interfaces:** Always funnel all calls to a process (Agent/GenServer) through a single module that acts as the exclusive API. Avoid spreading direct calls to `Agent.update/2`, `GenServer.call/3`, or similar across multiple modules. This makes the code easier to maintain, helps avoid data format inconsistencies, reduces duplication, and lowers bug risk.
- **Send minimal data between processes:** Extract and send only the required fields—not whole structs or large variables—to avoid unnecessary memory copies.
- **Always supervise long-lived processes:** Start all persistent processes under a supervision tree for lifecycle management and fault recovery.

**Elixir Documentation**
- **Format:** Elixir docs use Markdown (`@moduledoc`, `@doc`, `@typedoc`). Reference full module names with backticks (e.g., `MyApp.Hello`), functions by name/arity (`world/1`, `MyApp.Hello.world/1`), callbacks as `c:name/arity`, and types as `t:name/arity`.
- **Placement:** Place `@moduledoc` at module top, `@doc` before each function’s first clause. Document multi-clause functions before first clause.
- **Arguments:** Function argument names are inferred; for clarity, provide a separate function head before implementation if needed.
- **Metadata:** Pass keyword list (e.g., `@doc since: "1.0.0"`, `@doc deprecated: "message"`). `:since` annotates version. `:deprecated` in metadata shows warnings in docs only, use `@deprecated` attribute to warn on usage.
- **Style:**
    - Concise first paragraph for summaries.
    - Start sections with `##`.
    - Always write examples, they should use `## Examples` with `iex>` prompts for doctests—tested via ExUnit.DocTest. If examples can’t be doctested, omit `iex>`.
- **Public API:** All API modules & functions require documentation. Private functions should not use `@doc`.
- **Code Comments vs Documentation:** Docs are for API users; code comments are for maintainers. Avoid redundant comments.
- **Hiding Internals:** Use `@moduledoc false` to hide module, `@doc false` to hide function. Functions remain public and callable unless underscored; consider moving internals to hidden modules, or prefix with underscore for clarity.

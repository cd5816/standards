# Go Programming Guide for Coding Agents

This guide defines the default standards for writing, reviewing, and modifying Go code. Apply it unless repository-specific instructions, established project conventions, or explicit user requirements say otherwise.

This guide covers Go mechanics. It sits alongside `programming_style.md`,
which covers general design philosophy and applies to all languages
including Go. Read both.

## How to read this guide

This guide is long. Do not read it end to end for a small change. Read this
index, then extract only the sections your change touches:

    sed -n '/^## 12\./,/^## 13\./p' docs/go_programming_style_guide.md

Always read §1-3 (short) and §25-26 (verification and checklist). Read other
sections only when the index says they apply.

| § | Covers | Read when |
|---|---|---|
| 1 | Order of authority | always |
| 2 | Pre-change reconnaissance | always |
| 3 | Core principles | always |
| 4 | Formatting, imports, file organization | adding files or imports |
| 5 | Packages and module layout | adding/moving a package |
| 6 | Naming (vars, receivers, interfaces, errors) | naming anything new |
| 7 | Control flow | nontrivial branching |
| 8 | Functions, receivers, constructors | adding functions or methods |
| 9 | Data types, zero values, slices, maps, enums, time | defining types |
| 10 | Interface design, typed nil | defining or accepting interfaces |
| 11 | Generics | considering type parameters |
| 12 | Error handling, wrapping, sentinels | any code that returns errors |
| 13 | Context | any API crossing a call boundary |
| 14 | Resource ownership and cleanup | opening files, conns, goroutines |
| 15 | Concurrency | goroutines, channels, shared state |
| 16 | HTTP clients and servers | network code |
| 17 | Logging and configuration | log lines, flags, env |
| 18 | Dependencies and modules | touching go.mod |
| 19 | Testing | writing or changing tests |
| 20 | Performance | measured hot path only |
| 21 | Security and robustness | untrusted input, auth, crypto |
| 22 | Documentation and comments | exported API changes |
| 23 | Generated code, reflection, unsafe, CGO | rare; read before using any |
| 24 | Common anti-patterns | skim during self-review |
| 25 | Required verification commands | always, before committing |
| 26 | Completion checklist | always, before committing |

## 1. Order of authority

Follow guidance in this order:

1. Explicit user requirements.
2. Repository instructions such as `AGENTS.md`, `CONTRIBUTING.md`, and `README.md`.
3. Existing project architecture and conventions.
4. The Go version declared by `go.mod`.
5. This guide.
6. General Go community conventions.

Do not "clean up" unrelated code merely because it differs from this guide. Keep changes focused.

## 2. Before writing code

Before changing a Go repository:

- Read `go.mod` and note the `go` and `toolchain` directives.
- Do not use language features or standard-library APIs newer than the supported Go version. This guide assumes Go 1.22 or later; where older versions require different idioms, this is noted.
- Inspect nearby files and tests to understand established patterns.
- Search for existing implementations before introducing new helpers, interfaces, packages, or dependencies.
- Identify generated files from headers such as `// Code generated ... DO NOT EDIT.` Modify their generator instead.
- Determine whether the change affects public APIs, serialized data, database schemas, command-line behavior, or error semantics.
- Preserve unrelated user changes in the working tree.
- Prefer the smallest coherent change that solves the problem completely.

Do not automatically raise the module's Go version, replace dependencies, or reorganize the repository unless required.

## 3. Core principles

Write Go that prioritizes, in order:

1. Correctness
2. Clarity
3. Simplicity
4. Maintainability
5. Consistency
6. Performance

Prefer ordinary, explicit Go over clever abstractions. Code should be easy to read from top to bottom without requiring the reader to simulate hidden control flow.

A small amount of repetition is often preferable to a premature abstraction.

These principles are the Go-specific expression of `programming_style.md`,
which applies to all languages and should also be read. Where the two
overlap, this guide governs Go mechanics (naming, error handling,
concurrency idioms); the general guide governs design judgment (when to
abstract, what to make public, how visible cost should be). They should not
conflict; if they appear to, prefer this guide for Go-specific mechanics and
raise the discrepancy.

## 4. Formatting and source organization

### Formatting

- Run `gofmt` on every modified Go file.
- Use `goimports` if the repository already uses it.
- Never manually align code in a way that fights `gofmt`.
- Do not enforce an arbitrary line-length limit. If a line is difficult to read, simplify the expression rather than wrapping it mechanically.
- Keep control-flow opening braces on the same line.

### Imports

Organize imports using standard formatting: standard library first, then external packages, separated by a blank line.

```go
import (
	"context"
	"errors"
	"fmt"

	"example.com/project/internal/store"
)
```

- Do not use dot imports.
- Use blank imports only for documented side effects.
- Avoid import aliases unless resolving a collision or substantially improving clarity.
- Remove unused imports rather than assigning package symbols to `_`.
- Keep platform-specific imports in platform-specific files when practical.

### File organization

- Keep files cohesive rather than enforcing arbitrary size limits; split files with clearly separate responsibilities.
- Do not create files such as `utils.go`, `common.go`, or `helpers.go` as dumping grounds.
- Place tests in `_test.go` files.
- Use build tags only when necessary and test every relevant build configuration.

## 5. Packages and project structure

### Package design

Package names should be short, lowercase, a single word when practical, descriptive of what the package provides, and free of underscores or mixed capitalization.

Avoid vague package names such as `util`, `common`, `misc`, `helpers`, `types`, or `interfaces`.

Use the package name as part of the API. Avoid stuttering:

```go
// Good:
package user

type Profile struct{} // caller sees user.Profile

// Avoid:
type UserProfile struct{} // caller sees user.UserProfile
```

Additional rules:

- Avoid package import cycles; they usually indicate misplaced responsibilities.
- Prefer a small number of cohesive packages over many tiny packages.
- Use `internal/` when implementation packages should not be imported externally.
- Keep executable entry points small. Put reusable logic outside `package main`.
- Avoid unnecessary `init` functions. Never perform surprising network calls, start goroutines, or mutate external state from `init`.

### Module layout

Use the simplest layout that works: a flat module for libraries, `cmd/<name>/main.go` plus `internal/` for projects with commands.

Do not introduce `src/`, `pkg/`, or deeply nested directory trees without a concrete need or an existing repository convention.

## 6. Naming

### General naming

- Use `MixedCaps` or `mixedCaps`, never snake case.
- Use concise names whose meaning is clear from context; use longer names when scope or ambiguity requires them.
- Avoid encoding types into names.
- Avoid generic names such as `data`, `info`, `obj`, `manager`, or `handler` when a more precise name exists.
- Keep terminology consistent across APIs, implementations, tests, and documentation.

Common initialisms remain consistently capitalized: `userID`, `requestURL`, `HTTPClient`, `JSONEncoder`, `SQLStore`. Follow the repository's established initialism style when one exists.

### Variables

Short names are appropriate for small scopes (`i`, `n`, `buf`). Use descriptive names for values that live longer or require context (`retryDelay`).

Prefer units in types rather than names: `timeout time.Duration`. If a raw numeric unit is unavoidable, make it explicit: `timeoutSeconds int`.

### Receivers

Receiver names should be short, consistent across the type's methods, based on the type name, and never `this` or `self`:

```go
func (s *Server) Start() error
func (s *Server) Shutdown(ctx context.Context) error
```

### Getters and setters

Do not prefix ordinary getters with `Get`:

```go
func (u *User) Name() string
func (u *User) SetName(name string)
```

Use `Get` only when it is part of the domain operation or an established API convention.

### Interfaces

One-method interfaces commonly use an `-er` name when natural (`Reader`, `Closer`). Do not force awkward names merely to end in `-er`. Name interfaces for the behavior required by the consumer.

### Errors

- Exported sentinel errors use `ErrName`; exported error types use names such as `ParseError`.
- Error strings start lowercase (unless beginning with a proper noun) and do not end with punctuation.
- Do not include words such as "error" or "failed" when the context already communicates failure.

```go
var ErrNotFound = errors.New("not found")
```

## 7. Control flow

Keep the successful path visually clear. Prefer early returns:

```go
file, err := os.Open(name)
if err != nil {
	return fmt.Errorf("open %q: %w", name, err)
}
defer file.Close()

return process(file)
```

Avoid unnecessary `else` blocks after `return`, `break`, `continue`, or `panic`.

Use an initialization statement when it keeps a value appropriately scoped:

```go
if err := config.Validate(); err != nil {
	return fmt.Errorf("validate config: %w", err)
}
```

Additional guidance:

- Prefer `switch` when it expresses multiple related cases more clearly than an `if` chain.
- Do not use `fallthrough` unless the semantics genuinely require it.
- Avoid deeply nested control flow. Extract a function or return early.
- Be careful with `:=`; it may shadow variables from an outer scope. Never rely on subtle shadowing for correctness.
- Use labels only for clearly named breaks or continues across nested constructs.
- Avoid `goto` except in rare low-level code where it materially clarifies cleanup.
- Prefer the `min` and `max` builtins over hand-written comparisons when the Go version allows.

## 8. Functions and methods

Functions should do one coherent job.

- Keep parameter lists reasonably small; group related data into a type when it forms a real concept.
- Avoid boolean parameters whose meaning is unclear at the call site.
- Use named results when they clarify multiple values of the same type or enable necessary deferred cleanup. Avoid naked returns in nontrivial functions.
- Do not return pointers to interfaces. Interfaces already contain reference-like dynamic values.
- Accept a pointer only when mutation, identity, ownership, or avoiding a meaningful copy requires it.

### Receivers

Use a pointer receiver when the method mutates the receiver, the receiver contains a mutex or other non-copyable value, the receiver is large, identity matters, or other methods already use pointer receivers.

Use a value receiver when the type is small and naturally immutable and copying is safe and expected.

Do not mix receiver styles arbitrarily.

### Constructors

Go does not require a constructor for every type. Prefer a useful zero value when practical (`var buf bytes.Buffer`).

Use a constructor when it must enforce invariants, validate input, initialize hidden state, select an implementation, or acquire a resource.

Name a constructor `New` when the package exports one primary type, or `NewType` when needed for clarity.

Do not introduce functional options for a simple constructor with two or three stable arguments. Functional options are appropriate when optional configuration is substantial, evolving, and benefits from named call sites.

## 9. Data types and zero values

Design types so their zero values are useful whenever practical: empty slices, empty buffers, unlocked mutexes, zero durations, disabled optional behavior.

### `new` and `make`

- `new(T)`: rarely, when a pointer to a zero value is specifically useful.
- `make`: for initialized slices, maps, and channels.
- Composite literals for ordinary struct construction.

```go
items := make([]Item, 0, expectedCount)
index := make(map[string]Item)
queue := make(chan Job, queueSize)
```

### Struct literals

Use keyed fields across package boundaries and for structs likely to evolve. Positional literals are acceptable for small, stable, local types when unmistakably clear.

### Slices

- A slice is a descriptor referencing an underlying array; mutating elements may affect other slices sharing that array.
- `append` may allocate a new underlying array, so assign its result.
- Preallocate capacity when the final size is reasonably known.
- Do not retain a small subslice of a very large buffer; copy the needed data.
- Decide intentionally whether `nil` and empty slices differ in API or serialization meaning:

```go
var nilItems []Item      // Often encodes as null in JSON.
emptyItems := []Item{}   // Often encodes as [] in JSON.
```

- Prefer the standard `slices` package (`slices.Contains`, `slices.Sort`, `slices.Equal`, etc.) over hand-rolled loops when the Go version allows.

### Maps

- Reading from a nil map is safe; writing to one panics.
- Map iteration order is unspecified. Sort keys (e.g., with `slices.Sorted(maps.Keys(m))`) when deterministic output is required.
- Maps are not safe for unsynchronized concurrent access.
- Use the comma-`ok` idiom when absence differs from a zero value.

### Enums

Typed constants with `iota` are appropriate for compact enumerations:

```go
type State uint8

const (
	StateUnknown State = iota
	StatePending
	StateRunning
	StateDone
)
```

- Reserve a zero value that is safe and meaningful.
- Validate values received from external systems; do not assume future values are impossible.
- Preserve compatibility when values are serialized or stored.

### Time

- Use `time.Duration` for durations and `time.Time` for timestamps.
- Be explicit about UTC versus local time.
- Avoid comparing formatted time strings.
- Inject clocks or time-producing functions when deterministic tests need control over time.

## 10. Interface design

Interfaces describe behavior, not data. Prefer small interfaces defined near the consumer:

```go
type UserStore interface {
	FindUser(ctx context.Context, id string) (User, error)
}
```

General defaults:

- Accept interfaces when callers may reasonably provide different implementations. Return concrete types unless hiding implementations is an intentional API decision.
- Do not create an interface merely to mock one concrete type, and do not define an interface until at least one consumer needs the abstraction.
- Prefer standard interfaces such as `io.Reader`, `io.Writer`, and `fs.FS`.
- Avoid large "god interfaces" and unrelated behavior in one interface.

Compile-time interface assertions are useful when satisfaction is otherwise not checked statically:

```go
var _ io.Reader = (*Buffer)(nil)
```

Do not add assertions mechanically for every implementation.

### Typed nil in interfaces

An interface value holds a (type, value) pair. Storing a nil pointer in an interface produces an interface with a non-nil type — and a non-nil interface:

```go
var parseErr *ParseError   // nil pointer
var err error = parseErr   // err != nil, because err's type is *ParseError
```

Avoid returning typed nil values through interfaces; return a literal `nil` for the interface type instead.

## 11. Generics

Use generics when a function or type genuinely operates over multiple types with the same semantics: reusable algorithms, type-safe containers, or removing substantial duplication that differs only by type.

Do not use generics to replace ordinary interface-based behavior, for a single known type, to save a few trivial repeated lines, or as a speculative extension point.

Check the standard library first: `slices`, `maps`, and `cmp` already provide most common generic helpers. Do not reimplement `slices.Contains` or `slices.IndexFunc`.

Prefer the smallest constraint that expresses the operation:

```go
// Merge returns a new map containing entries from all inputs;
// later maps win on key conflicts.
func Merge[K comparable, V any](ms ...map[K]V) map[K]V {
	out := make(map[K]V)
	for _, m := range ms {
		for k, v := range m {
			out[k] = v
		}
	}
	return out
}
```

Additional rules:

- Use `any` rather than `interface{}` unless local conventions differ.
- Use `~T` in constraints only when underlying types are intentionally accepted.
- Prefer interfaces for runtime behavioral polymorphism; prefer type parameters for compile-time relationships among types.
- Do not assume generics improve performance; benchmark relevant code.
- Avoid exposing complicated constraints as public APIs without a clear benefit.

## 12. Error handling

Errors are ordinary values and the primary mechanism for expected failures.

### Returning errors

Return errors rather than panicking for any condition callers may handle: invalid input, missing data, network or file failure, auth failure, cancellation, dependency failure.

Handle every meaningful error. Do not discard errors using `_` unless the operation is explicitly safe to ignore and the reason is documented.

### Adding context

Wrap errors with useful operational context describing what failed, not merely announcing failure:

```go
item, err := store.Load(ctx, id)
if err != nil {
	return Item{}, fmt.Errorf("load item %q: %w", id, err)
}
```

Avoid filler like `"failed to ..."` — the error position already communicates failure.

### `%w` versus `%v`

**Default to `%w`.** Wrapping preserves the error chain for `errors.Is` and `errors.As`, and most callers benefit from it.

Use `%v` (or create a new domain error) deliberately when the underlying error must remain hidden — typically when `%w` would couple callers to a private implementation detail or an internal dependency you may replace. Treat which errors you wrap as part of the observable API.

Use `errors.Join` when multiple independent failures must be reported together (e.g., cleanup errors from several resources); `errors.Is`/`errors.As` traverse all joined errors.

### Inspecting errors

```go
if errors.Is(err, ErrNotFound) { /* ... */ }

var validationErr *ValidationError
if errors.As(err, &validationErr) { /* ... */ }
```

Do not compare or parse error strings, use direct equality on possibly-wrapped errors, or type-assert only the outermost error.

### Logging and returning

Handle an error at the correct layer: either return it with context or log it where the operation is finally handled — not both at every layer, which produces duplicate noisy logs.

Libraries generally should not log errors they return. Applications should log at process or request boundaries.

### Sentinel and typed errors

Use a sentinel error (`var ErrNotFound = errors.New("not found")`) when callers need to recognize a stable category. Use a custom type when callers need structured details:

```go
type ValidationError struct {
	Field string
	Issue string
}

func (e *ValidationError) Error() string {
	return fmt.Sprintf("%s: %s", e.Field, e.Issue)
}
```

Do not expose more error taxonomy than callers genuinely need.

### Panic and recover

Use `panic` only for programmer bugs, broken internal invariants, initialization that makes continued execution impossible, or APIs explicitly documented as `Must...`. Never for normal error handling.

Use `recover` only at carefully chosen boundaries, such as isolating a request or plugin, and recover only failures the boundary understands. Unexpected failures should generally be logged with a stack and allowed to fail according to application policy.

## 13. Context

Use `context.Context` for cancellation, deadlines, and request-scoped values across API boundaries.

- Pass context as the first parameter, named `ctx`.
- Do not pass `nil`; use `context.Background()` or `context.TODO()`.
- Propagate the caller's context rather than replacing it.
- Do not store context in a struct except when an established framework requires it.
- Call cancellation functions returned by `context.WithCancel`, `WithTimeout`, or `WithDeadline`.
- Stop work promptly when `ctx.Done()` is closed; return or wrap `ctx.Err()` when cancellation is the cause.
- Do not use context values for ordinary parameters or configuration. Context values carry request-scoped metadata only, keyed by private key types.

```go
func (s *Service) Lookup(ctx context.Context, id string) (Item, error) {
	if err := ctx.Err(); err != nil {
		return Item{}, err
	}

	item, err := s.store.Load(ctx, id)
	if err != nil {
		return Item{}, fmt.Errorf("load item %q: %w", id, err)
	}
	return item, nil
}
```

## 14. Resource ownership and cleanup

Make ownership explicit. The code that acquires a resource is usually responsible for releasing it unless ownership is explicitly transferred.

Defer cleanup immediately after successful acquisition — never before checking the acquisition error:

```go
file, err := os.Open(path)
if err != nil {
	return err
}
defer file.Close()
```

For writable resources, closing may report important buffered-write errors. Preserve them:

```go
func writeFile(path string, data []byte) (err error) {
	file, err := os.Create(path)
	if err != nil {
		return fmt.Errorf("create %q: %w", path, err)
	}

	defer func() {
		if closeErr := file.Close(); err == nil && closeErr != nil {
			err = fmt.Errorf("close %q: %w", path, closeErr)
		}
	}()

	if _, err := file.Write(data); err != nil {
		return fmt.Errorf("write %q: %w", path, err)
	}
	return nil
}
```

Additional rules:

- Do not accumulate `defer` calls inside an unbounded loop; use an inner function.
- Close HTTP response bodies after every successful request. If the remaining body is small and connection reuse matters, drain it before closing (e.g., `io.Copy(io.Discard, io.LimitReader(resp.Body, maxDrain))`); for large or unbounded bodies, just close — do not drain unbounded data to save a connection.
- Stop tickers when no longer needed; avoid repeatedly allocating `time.After` timers in hot loops.
- Bound reads from untrusted or potentially large inputs.
- Remember that `bufio.Scanner` has a token-size limit; configure it or use another reader when larger tokens are valid.

## 15. Concurrency

Concurrency must have an explicit reason and lifecycle.

### Goroutine ownership

For every goroutine, determine: who starts it, what it owns, how it stops, how cancellation is communicated, who waits for it, where its errors go, whether it can block forever, and whether its concurrency is bounded.

Do not start a goroutine unless its termination behavior is clear.

Prefer synchronous APIs by default. Let callers decide whether to invoke ordinary functions concurrently unless the implementation itself requires concurrency.

### Communication and shared state

Use channels when communication or ownership transfer is central. Use mutexes when protecting shared state is simpler and clearer. "Share memory by communicating" is useful guidance, not a prohibition against mutexes.

- Protect invariants, not merely individual fields.
- Keep critical sections small; do not hold a mutex during slow I/O or callbacks unless required.
- Never copy a value containing `sync.Mutex`, `sync.Once`, atomic values, or similar synchronization state after first use.
- Use atomics only for simple, well-understood state transitions.
- Maps require synchronization when accessed concurrently with at least one writer.
- Run race-sensitive tests with `go test -race`.

### Channels

- The sender that owns production normally closes the channel; receivers should not close a channel they do not own.
- Closing signals that no more values will be sent; it is not a general-purpose cleanup mechanism. Sending to or closing a closed channel panics.
- Use directional channel types (`chan<-`, `<-chan`) in APIs when they clarify ownership.
- Use buffered channels only with a reasoned capacity; do not use a large buffer to hide backpressure.
- Avoid `select { default: }` loops that spin and consume CPU.
- Operations on a nil channel block forever; use that behavior only deliberately.

### Bounded concurrency

Never create unbounded goroutines from unbounded input. Use fixed worker pools, semaphores, bounded queues, request limits, and context cancellation. Ensure all workers exit on completion, cancellation, or error.

### Loop variables and closures

Since Go 1.22, `for` loop variables are scoped per iteration; capturing them in a goroutine closure is safe:

```go
for _, job := range jobs {
	go func() {
		process(job)
	}()
}
```

Only if the module declares a Go version below 1.22 must you rebind (`job := job`) or pass the value as a parameter. Do not add redundant rebinding on modern toolchains; linters flag it. Explicit parameter passing is still fine when the variable is later reassigned or mutated and clarity benefits.

### Waiting and errors

- Add work to a `sync.WaitGroup` before starting the goroutine; ensure each increment has exactly one completion.
- Do not lose errors produced by background work (consider `errgroup`).
- On the first fatal error, cancel related work when continued execution is unnecessary.
- Avoid goroutine leaks caused by blocked sends after a receiver exits.

## 16. HTTP and network services

### Clients

- Reuse `http.Client` and transports rather than creating one per request.
- Configure a timeout or use request contexts with deadlines; create requests with `http.NewRequestWithContext`.
- Check the response error before accessing `resp`; close successful response bodies.
- Bound response-body reads.
- Treat non-2xx status codes according to the API contract; do not assume every error response is JSON.
- Do not log credentials, tokens, authorization headers, or sensitive bodies.

### Servers

Configure explicit timeouts appropriate to the service:

```go
server := &http.Server{
	Addr:              address,
	Handler:           handler,
	ReadHeaderTimeout: 5 * time.Second,
	ReadTimeout:       30 * time.Second,
	WriteTimeout:      30 * time.Second,
	IdleTimeout:       2 * time.Minute,
}
```

Choose values based on workload rather than copying these blindly. In particular, `WriteTimeout` (and `ReadTimeout` for long uploads) will kill streaming, SSE, and long-poll endpoints; for those, rely on per-request context deadlines or `ResponseController.SetWriteDeadline` instead of a blanket server timeout.

Additional rules:

- Use `req.Context()` for request-scoped work.
- Limit request-body size (`http.MaxBytesReader`) before decoding untrusted bodies; validate content types and inputs.
- Write headers before the response body.
- Do not expose internal error details to clients; return stable, documented error formats for public APIs.
- Support graceful shutdown for long-lived servers.
- Ensure background work does not silently outlive its originating request unless explicitly detached and owned elsewhere.
- Use `httptest` for handler and client tests.

## 17. Logging and configuration

### Logging

Use the repository's established logging package. For new standard-library-based applications, prefer structured logging with `log/slog`.

- Log at system boundaries with consistent structured field names and enough context to diagnose the operation.
- Never log secrets, tokens, passwords, private keys, or sensitive payloads.
- Avoid package-level logger configuration in libraries; libraries must not terminate the process.
- Do not call `log.Fatal` outside application startup or another true process boundary.

### Configuration

- Parse configuration near the application boundary and pass typed configuration into components explicitly.
- Validate configuration before starting work.
- Use `time.Duration`, URLs, and other semantic types rather than raw strings where practical.
- Avoid reading environment variables deep inside reusable packages.
- Distinguish unset values from explicit zero values when the distinction matters.
- Never silently choose dangerous security defaults.

## 18. Dependencies and modules

Prefer the standard library when it provides a clear, robust solution. Do not reimplement a mature external solution merely to avoid all dependencies, but justify each new dependency: maintenance status, license, API stability, transitive size, security history, whether the repository already uses an equivalent, and whether a small local implementation would be clearer.

Module rules:

- Preserve `go.mod` and `go.sum`. Use `go mod tidy` after intentional dependency changes and review its diff; do not accept unrelated upgrades blindly.
- Do not commit `replace` directives intended only for local development.
- Respect vendoring if the project uses `vendor/`.
- Preserve the project's minimum supported Go version.
- Avoid importing another module's `internal` packages.
- Follow semantic import versioning for modules at version 2 or higher.
- Keep dependency updates focused and test them separately from unrelated behavior changes when possible.

## 19. Testing

Tests should verify externally meaningful behavior and important invariants.

### General practices

- Put tests near the code they verify; use the standard `testing` package unless the repository already uses another framework.
- Prefer deterministic tests. Avoid real network services, wall-clock sleeps, and global mutable state.
- Use `t.TempDir()`, `t.Setenv()`, and `t.Cleanup()`. On Go 1.24+, use `t.Context()` for a context canceled when the test ends.
- Call `t.Helper()` in test helpers.
- Make failure messages identify what happened and what was expected.
- Test success, failure, boundary conditions, malformed inputs, and (when relevant) cancellation and timeouts.
- Compare errors with `errors.Is` or `errors.As`, not strings.
- Do not call `t.Fatal` or `t.FailNow` from a goroutine other than the test's own.

### Table-driven tests

Use table-driven tests when several cases share meaningful setup and assertions:

```go
func TestParseState(t *testing.T) {
	tests := []struct {
		name    string
		input   string
		want    State
		wantErr error
	}{
		{name: "pending", input: "pending", want: StatePending},
		{name: "unknown", input: "invalid", wantErr: ErrInvalidState},
	}

	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			got, err := ParseState(test.input)
			if !errors.Is(err, test.wantErr) {
				t.Fatalf("ParseState(%q) error = %v, want %v", test.input, err, test.wantErr)
			}
			if err == nil && got != test.want {
				t.Errorf("ParseState(%q) = %v, want %v", test.input, got, test.want)
			}
		})
	}
}
```

(On modules below Go 1.22, add `test := test` before `t.Run` when subtests run in parallel.)

Do not force a one-case test or highly divergent scenarios into a table.

### Parallel tests

Use `t.Parallel()` only when the test does not mutate shared global state, dependencies are concurrency-safe, parallelism does not introduce flakiness, and resource consumption remains bounded.

### Time-dependent tests

Do not synchronize tests with arbitrary sleeps. Prefer channels, contexts, fake clocks, or polling with a bounded deadline. All waits must have a timeout so failures do not hang.

### Golden files

Golden files suit substantial structured output. Keep update behavior explicit (an `-update` flag), review golden diffs, and normalize inherently unstable fields before comparison.

### Fuzzing

Use fuzz tests for parsers, decoders, protocol boundaries, and functions with large or hostile input spaces. Verify invariants: no unexpected panic, round-trip stability, valid output, bounded resource use.

### Benchmarks

Benchmark only meaningful operations. On Go 1.24+, prefer `for b.Loop() { ... }`, which keeps setup out of the timed section and prevents compiler elimination of the measured operation; on older versions, use `b.ResetTimer` and sink results deliberately. Report allocations when relevant, and do not optimize based solely on microbenchmarks.

## 20. Performance

Write clear code first. Optimize only when benchmarks, profiles, traces, or production metrics show that performance matters.

Reasonable low-complexity optimizations:

- Preallocating slices when size is known
- `strings.Builder` for incremental string construction; `bytes.Buffer` for byte-oriented buffering
- Avoiding repeated conversions in hot loops
- Streaming large data instead of loading it all into memory

Avoid speculative complexity: manual object pools, unsafe pointer tricks, custom allocators, lock-free algorithms, reflection-heavy frameworks, caching without invalidation and ownership rules.

Additional guidance:

- `sync.Pool` is not a durable cache; its contents may disappear at any time.
- Do not assume pointer use avoids allocations; use escape analysis and benchmarks.
- Beware that ranging over a slice of large structs copies each element.
- Document why non-obvious performance code is necessary and include a benchmark when practical.

## 21. Security and robustness

Treat data from files, networks, command lines, environment variables, databases, and external APIs as untrusted.

- Validate inputs at trust boundaries; bound input sizes, concurrency, retries, and memory growth.
- Use deadlines and cancellation for external calls.
- Use `crypto/rand` for security-sensitive randomness; never `math/rand` for secrets, tokens, keys, or nonces.
- Use parameterized SQL queries.
- Do not construct shell commands through string concatenation; pass arguments directly to `exec.CommandContext`.
- Verify filesystem paths remain within their intended root; cleaning a path alone does not prove confinement (consider `os.Root` on Go 1.24+).
- Use restrictive file permissions for secrets; keep secrets out of logs, metrics labels, command lines, and error messages.
- Use standard cryptographic and TLS implementations; do not disable certificate verification outside an explicitly isolated test.
- Avoid decompressing or decoding unbounded attacker-controlled data; consider algorithmic denial-of-service behavior for maps, parsers, regexes, and recursion.
- Run `govulncheck` when available; update vulnerable dependencies deliberately and verify compatibility.

## 22. Documentation and comments

Comments should explain purpose, constraints, ownership, invariants, and reasons — not restate syntax.

Exported declarations should have doc comments when they form a public API, beginning with the declared name and written as complete sentences:

```go
// Server accepts and processes API requests.
type Server struct{ /* ... */ }

// Shutdown gracefully stops the server.
func (s *Server) Shutdown(ctx context.Context) error { /* ... */ }
```

Guidelines:

- Keep documentation accurate when behavior changes.
- Document concurrency safety, blocking behavior, important error behavior, non-obvious nil handling, and whether callers retain ownership of slices, maps, readers, writers, or returned buffers.
- Include examples for APIs that are difficult to use correctly.
- Explain temporary workarounds with an issue reference or removal condition.
- Do not leave commented-out code; version control preserves history.
- Use `TODO(name):` or the repository's convention for actionable follow-up work — but do not add a TODO instead of completing work already in scope.

## 23. Generated code, reflection, `unsafe`, and CGO

### Generated code

Modify the generator rather than generated output. Ensure generated code is deterministic, includes the standard header, and is regenerated after schema or template changes. Verify generated diffs rather than assuming they are correct.

### Reflection

Use reflection only when the problem is inherently runtime-typed (serialization, framework integration, schema processing). Prefer static types, interfaces, generics, and explicit code. Reflection-heavy code should validate kinds and types before operations and return useful errors rather than panicking.

### `unsafe`

Use `unsafe` only with a measured, material need, inadequate safe alternatives, documented invariants, isolation, tests covering boundary and lifetime behavior, and explicit compatibility assumptions.

### CGO

Avoid introducing CGO without a concrete requirement. It affects portability, cross-compilation, deployment, performance, and memory ownership. Document and test platform requirements.

## 24. Common anti-patterns

The sections above imply most anti-patterns; the following deserve explicit mention because they recur in generated and ported code:

- Translating Java, C++, or framework-heavy architecture directly into Go
- Creating an interface for every struct, or a mock-only interface per type
- Giant "manager," "service," or "util" types with unrelated responsibilities
- Mutable package-level global state and hidden work in `init`
- Using `map[string]any` instead of a known domain type; manual string-built JSON
- Broad refactoring mixed into a focused bug fix
- Lint suppressions without a specific explanation
- Reimplementing `slices`/`maps`/`errors` stdlib functionality

## 25. Required verification

After changing Go code, run the checks appropriate to the change and repository.

Minimum:

```sh
gofmt -w <modified-go-files>
go test ./...
```

Common additional checks:

```sh
go vet ./...
go test -race ./...
go build ./...
govulncheck ./...
staticcheck ./...
```

Rules:

- Use repository-provided commands such as `make test`, `task test`, or CI scripts when authoritative.
- Do not run `go mod tidy` unless module changes are intended or the repository expects it.
- Run targeted tests during development, then the broadest practical suite before completion.
- Test relevant build tags and operating systems when the change is platform-specific.
- Verify generated files are current, and inspect the final diff for accidental formatting, dependency, or API changes.
- If a check cannot run, state exactly which check was skipped and why.
- Never claim tests passed unless they were actually executed successfully.

## 26. Completion checklist

Before declaring a Go change complete, verify:

- [ ] The implementation satisfies the requested behavior.
- [ ] Repository instructions were followed.
- [ ] The code supports the Go version declared by the module.
- [ ] Modified files are formatted with `gofmt`; imports are correct and minimal.
- [ ] Public APIs changed only when necessary, and exported behavior is documented.
- [ ] Errors contain useful context, are inspected with `errors.Is`/`errors.As` where appropriate, and none are silently ignored.
- [ ] Resources are released on every path.
- [ ] Context cancellation and deadlines are propagated.
- [ ] Every new goroutine has a clear termination path; concurrency is bounded; shared state is synchronized.
- [ ] Inputs and external data are bounded and validated; secrets and internal details are not exposed.
- [ ] Tests cover success, failure, and relevant boundary cases.
- [ ] Relevant tests, builds, vetting, and race checks pass.
- [ ] Dependency changes are intentional and reviewed; generated code is current.
- [ ] The final diff contains no unrelated changes.

## References

- [Effective Go](https://go.dev/doc/effective_go)
- [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments)
- [Go Test Comments](https://go.dev/wiki/TestComments)
- [Go Doc Comments](https://go.dev/doc/comment)
- [The Go Memory Model](https://go.dev/ref/mem)
- [Go Modules Reference](https://go.dev/ref/mod)
- [Working with Errors in Go](https://go.dev/blog/go1.13-errors)
- [Google Go Style Guide](https://google.github.io/styleguide/go/)
- [Google Go Style Decisions](https://google.github.io/styleguide/go/decisions)
- [Google Go Best Practices](https://google.github.io/styleguide/go/best-practices)

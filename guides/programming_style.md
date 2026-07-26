# General Programming Style

My default approach to writing code, in every language. Read this before
substantive coding work regardless of what language-specific guide also
applies — including Go.

Language-specific guides (e.g. `go_programming_style_guide.md`) cover
mechanics and idioms for their language. This file covers design judgment
and applies on top of them.

The examples below use Rust syntax (`&self`, `pub`, derives) because that is
where the style was worked out. Translate to the language at hand: `pub` →
exported identifiers, `&self`/`&mut self` → value vs pointer receivers, and
so on. The rules are general.

---

## Core Principle

Write the simplest correct code first.
Add abstraction only when it clearly reduces bugs, duplication, or cognitive load.

---

## Style Influence

This style is heavily influenced by Casey Muratori: procedural-first, explicit, data-oriented, skeptical of premature abstraction, and biased toward visible cost and debuggable code.

When in doubt, follow the concrete rules below over the label.

---

## Default Rules

- Start with straightforward procedural code and explicit control flow.
- Prefer free functions first.
- Keep parameters explicit so data flow stays obvious at call sites.
- Extract a function after repeated logic appears *(rule of thumb: 2+ occurrences)*.
- Introduce a struct when values repeatedly travel together or form one coherent concept.
- Group related code in modules.
- Keep items private by default; make them `pub` only when callers need them.
- Expose the smallest public API that keeps call sites clear.
- Use module boundaries to hide implementation details and protect invariants.
- Build higher-level helpers by compressing existing lower-level code.
- Keep lower-level operations available when adding convenience APIs.
- Keep true internals private, but do not hide the lower-level operations callers need to replace a convenience API.
- A higher-level function should be trivially replaceable by a small sequence of lower-level calls that does the same work.
- Use method receivers intentionally:
    - `&self` for read-only behavior
    - `&mut self` for mutation
    - `self` for consuming or transferring ownership
- Enforce invariants at boundaries when invalid states are possible.
- Add traits only when multiple types share behavior or APIs should target capabilities.
- Prefer derives (`Debug`, `Clone`, etc.) before custom impls unless custom behavior is needed.

---

## Data and Cost Model

- Prefer plain data structures whose layout, ownership, and lifetime are obvious.
- Let data layout and access patterns inform design in hot or frequently-run code.
- Make allocation, copying, borrowing, and ownership transfer visible at call sites.
- Prefer contiguous storage and simple iteration patterns when performance matters.
- Prefer direct calls and static dispatch; use dynamic dispatch only when runtime flexibility is truly needed.
- Prefer enums over trait-object style polymorphism when the set of cases is known.
- Prefer explicit loops when combinators or iterator chains hide control flow or cost.
- Keep important code easy to step through in a debugger.
- Keep a rough cost model in mind while writing code.
- Prefer straightforward runtime checks at boundaries over deep type-level encoding when the latter makes code harder to read, debug, or change.

---

## Escalate Abstraction When

- Call sites are noisy or confusing.
- Invariants are hard to maintain with public raw data.
- Free-function naming or discovery becomes messy at scale.
- Multiple types need shared behavior.
- A repeated sequence of lower-level operations has become stable enough to compress into a convenience API.

---

## Avoid

- Premature abstraction or speculative architecture.
- Traits, lifetimes, generics, or indirection before they solve a real problem.
- Hiding important state transitions behind abstraction.
- Attaching methods by default when free functions are clearer.
- Convenience APIs that become all-or-nothing traps.
- Hiding state or transitions so thoroughly that one special case forces a full rewrite at a lower level.
- Compression that hurts local understanding.
- Hidden heap allocation in convenience APIs.
- Hidden copies or clones that obscure cost.
- Indirection that makes it hard to tell where data lives or when work happens.
- Open-ended polymorphism when a closed set of cases would be clearer.
- Type-level machinery that obscures the program more than it protects it.

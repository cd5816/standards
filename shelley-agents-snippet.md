<!-- standards:begin (managed by ~/standards/install.sh; do not edit between markers) -->

## Personal standards library

This VM has a standards library at `~/standards`
(https://github.com/cd5816/standards) containing coding guides in
`~/standards/guides/`. Before substantive work in a domain covered by a
guide, read the relevant guide. Guides are defaults: explicit user
instructions and repository conventions take precedence.

The library is read-only on this VM: pull updates with
`git -C ~/standards pull --ff-only`; never commit or push to it from here.

### General programming style

Read `~/standards/guides/programming_style.md` before substantive coding
work in any language, including languages with a specific guide below. It
is short and always applies. Language-specific guides add mechanics on top
of it; they do not replace it.

### Go projects

When working in a Go repository (`go.mod` present):

- If the repo has `docs/go_programming_style_guide.md`, read its "How to
  read this guide" index before nontrivial changes and load only the
  sections that apply. Do not read the whole file. Always follow §25 and
  §26 before committing.
- If the repo lacks the guide and the work is substantive, set it up
  first: `git -C ~/standards pull --ff-only` (best effort) then
  `~/standards/install.sh <repo-path>`, and fill in the placeholders in
  the generated `AGENTS.md`. Ask first if the change is trivial. If
  `AGENTS.md` already exists, install.sh leaves it alone — merge the
  template's "Go style" and "Before committing" sections in by hand.

### Frontend / design work

If `~/standards/guides/DESIGN.md` exists, read it before frontend or UI
design work.

<!-- standards:end -->

Here it is with the general programming style section added (placed first, since it applies to all languages, with the precedence rule stated):

```markdown
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
work in any language. Language-specific guides (below) take precedence
where they overlap.

### Go projects

When working in a Go repository (`go.mod` present):

- If the repo has `docs/go_programming_style_guide.md`, read it before
  nontrivial Go changes and follow its §25 verification commands and §26
  completion checklist before committing.
- If the repo does NOT have the guide and you are doing substantive Go work,
  set it up first (or ask the user if the change is trivial):
  1. `git -C ~/standards pull --ff-only` (best effort; offline is fine)
  2. Copy `~/standards/guides/go_programming_style_guide.md` into the
     repo's `docs/` directory.
  3. Create the repo's `AGENTS.md` from
     `~/standards/templates/AGENTS.md.go.template`, filling in the project
     specifics by reading the code. If an `AGENTS.md` already exists, merge
     the template's "Go style" and "Before committing" sections into it
     instead of overwriting.
  4. Verify the repo passes the guide's §25 checks (gofmt, vet, build,
     test -race), then commit the new files.

### Frontend / design work

If `~/standards/guides/DESIGN.md` exists, read it before frontend or UI
design work.

<!-- standards:end -->
```

Save that over `shelley-agents-snippet.md`, make sure `guides/programming_style.md` is in place, then commit and push both. Once it's up, tell me and I'll pull + re-run `install.sh` here so this VM picks it up.

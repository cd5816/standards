# standards

Single source of truth for my coding standards across exe.dev VMs: style
guides, project templates, and agent workflow.

**Edited and pushed only from my computer.** VMs are read-only consumers
that clone/pull over HTTPS — no write credentials on any VM.

## Contents

| Path | Purpose |
|---|---|
| `guides/` | Coding guides (Go style guide, DESIGN.md, future Rust guide, …) |
| `templates/` | Project file skeletons (e.g. `AGENTS.md.go.template`) |
| `shelley-agents-snippet.md` | Managed block installed into `~/.config/shelley/AGENTS.md` |
| `install.sh` | Installs the snippet VM-wide; optionally sets up a Go project |

## Setup on a new VM

Tell the agent: *"Set up my standards from github.com/cd5816/standards"* — or
run it yourself:

```sh
git clone https://github.com/cd5816/standards ~/standards
~/standards/install.sh
```

Optionally set up a Go project at the same time:

```sh
~/standards/install.sh ~/path/to/project
# then edit the project's AGENTS.md placeholders and commit
```

## Updating standards

Edit on my computer, commit, push. On each VM (or ask the agent):

```sh
git -C ~/standards pull --ff-only && ~/standards/install.sh
```

Re-running `install.sh` refreshes the managed block in
`~/.config/shelley/AGENTS.md`; it never duplicates it.

## Design decisions

- **Projects get a copy of guides**, not a reference to `~/standards`:
  repos stay self-contained; drift is acceptable because guides are
  defaults, not law.
- **Design time + commit time**: agents read the relevant guide before
  nontrivial work (design decisions are cheap to guide, expensive to
  rework), and run mechanical checks (for Go: `gofmt`, `go vet`,
  `go build`, `go test -race`, then the guide's completion checklist)
  before committing.
- **Adding a new guide**: drop it in `guides/`, add a section to
  `shelley-agents-snippet.md` describing when agents should read it,
  push, then pull + re-run `install.sh` on each VM.

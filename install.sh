#!/bin/sh
# install.sh - wire the standards library into this VM, and optionally
# set up a Go project.
#
# Usage:
#   ./install.sh              # install VM-level agent instructions
#   ./install.sh <repo-path>  # ...and also set up a specific Go repo
#
# Idempotent: safe to re-run after `git pull` to refresh the managed
# snippet in ~/.config/shelley/AGENTS.md.
set -eu

SELF_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
GO_GUIDE="$SELF_DIR/guides/go_programming_style_guide.md"
GO_TEMPLATE="$SELF_DIR/templates/AGENTS.md.go.template"
SNIPPET="$SELF_DIR/shelley-agents-snippet.md"
SHELLEY_AGENTS="$HOME/.config/shelley/AGENTS.md"

BEGIN_MARK='<!-- standards:begin'
END_MARK='<!-- standards:end -->'
# Older installs used a different marker; migrate them too.
OLD_BEGIN_MARK='<!-- go-standards:begin'
OLD_END_MARK='<!-- go-standards:end -->'

for f in "$GO_GUIDE" "$GO_TEMPLATE" "$SNIPPET"; do
    [ -f "$f" ] || { echo "missing $f (clone incomplete?)" >&2; exit 1; }
done

# --- 1. VM level: manage the snippet inside ~/.config/shelley/AGENTS.md ---
mkdir -p "$(dirname "$SHELLEY_AGENTS")"
touch "$SHELLEY_AGENTS"

strip_block() { # strip_block <begin> <end> <file>
    tmp=$(mktemp)
    awk -v begin="$1" -v end="$2" '
        index($0, begin) { skip = 1 }
        !skip { print }
        skip && index($0, end) { skip = 0 }
    ' "$3" >"$tmp"
    mv "$tmp" "$3"
}

updated=false
if grep -qF "$OLD_BEGIN_MARK" "$SHELLEY_AGENTS"; then
    strip_block "$OLD_BEGIN_MARK" "$OLD_END_MARK" "$SHELLEY_AGENTS"
    updated=true
fi
if grep -qF "$BEGIN_MARK" "$SHELLEY_AGENTS"; then
    strip_block "$BEGIN_MARK" "$END_MARK" "$SHELLEY_AGENTS"
    updated=true
fi
{ [ -s "$SHELLEY_AGENTS" ] && printf '\n'; cat "$SNIPPET"; } >>"$SHELLEY_AGENTS"
if [ "$updated" = true ]; then
    echo "updated managed block in $SHELLEY_AGENTS"
else
    echo "appended managed block to $SHELLEY_AGENTS"
fi

# --- 2. Go project level (optional) ---
[ $# -eq 0 ] && exit 0

REPO=$1
[ -d "$REPO" ] || { echo "no such directory: $REPO" >&2; exit 1; }

REPO_ABS=$(CDPATH= cd -- "$REPO" && pwd)
[ "$REPO_ABS" = "$HOME" ] && { echo "refusing to install into \$HOME — pass a project directory" >&2; exit 1; }
[ "$REPO_ABS" = "$SELF_DIR" ] && { echo "refusing to install into the standards library itself" >&2; exit 1; }

[ -f "$REPO/go.mod" ] || echo "warning: $REPO has no go.mod" >&2

mkdir -p "$REPO/docs"
cp "$GO_GUIDE" "$REPO/docs/go_programming_style_guide.md"
echo "copied guide to $REPO/docs/go_programming_style_guide.md"

if [ -f "$REPO/AGENTS.md" ]; then
    echo "$REPO/AGENTS.md already exists; not touching it."
    echo "Merge sections from $GO_TEMPLATE manually if needed."
else
    cp "$GO_TEMPLATE" "$REPO/AGENTS.md"
    echo "created $REPO/AGENTS.md from template — EDIT IT: fill in the <PLACEHOLDERS>."
fi

cat <<'EOF'

Next steps in the project repo:
  1. Edit AGENTS.md: fill in every <PLACEHOLDER>.
  2. Verify: gofmt -l . && go vet ./... && go build ./... && go test -race ./...
  3. git add AGENTS.md docs/go_programming_style_guide.md && git commit
EOF

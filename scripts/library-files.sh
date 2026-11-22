#!/usr/bin/env bash
# Give one library repository the organisation's agent files from templates/library/: the
# Claude adapter (.claude/settings.json: core's hooks, the Farmhand bridge allowed, the
# transitional haywire-dev plugin off), .mcp.json (the bridge), t3.json (worktree setup,
# finish, studio), the [tool.haywire.agents] table in pyproject.toml, the machine-local
# .haywire files in .gitignore, and CLAUDE.md's workflow paragraph.
#
#   scripts/library-files.sh going-haywire/haybale-<name>           # show the diff it would propose
#   scripts/library-files.sh going-haywire/haybale-<name> --apply   # open the pull request
#
# It works in a fresh clone in a temporary folder, never in a working copy. Safe to run
# again: a file already as the template has it is left alone. Needs git, gh and python3.
set -euo pipefail

usage() {
  echo "usage: $0 going-haywire/haybale-<name> [--apply]" >&2
  exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage
REPO=$1
APPLY=false
if [[ $# -eq 2 ]]; then
  [[ $2 == --apply ]] || usage
  APPLY=true
fi
[[ $REPO == going-haywire/haybale-* ]] || {
  echo "$REPO is not a library of the organisation (going-haywire/haybale-*)" >&2
  exit 2
}
TEMPLATE=$(cd "$(dirname "$0")/.." && pwd)/templates/library
BRANCH=chore/agent-adapters
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

gh repo clone "$REPO" "$WORK/repo" -- --quiet --depth 1
cd "$WORK/repo"
git switch --quiet -c "$BRANCH"

cp "$TEMPLATE/.mcp.json" .mcp.json
cp "$TEMPLATE/t3.json" t3.json
python3 - "$TEMPLATE" <<'PY'
import json
import re
import sys
from pathlib import Path

template = Path(sys.argv[1])

# .claude/settings.json: the template's keys over the library's own, without the plugin's
# marketplace (the plugin stays switched off until the organisation removes it).
path = Path(".claude/settings.json")
settings = json.loads(path.read_text()) if path.exists() else {}
settings.pop("extraKnownMarketplaces", None)
settings.update(json.loads((template / ".claude" / "settings.json").read_text()))
path.parent.mkdir(exist_ok=True)
path.write_text(json.dumps(settings, indent=2) + "\n")

pyproject = Path("pyproject.toml")
text = pyproject.read_text()
if "[tool.haywire.agents]" not in text:
    pyproject.write_text(text.rstrip("\n") + "\n" + (template / "pyproject.agents.toml").read_text())

gitignore = Path(".gitignore")
lines = gitignore.read_text().splitlines() if gitignore.exists() else []
wanted = (template / "gitignore.agents").read_text().splitlines()
missing = [line for line in wanted if line.startswith(".haywire/") and line not in lines]
if missing:
    block = [line for line in wanted if not line.startswith(".haywire/") or line in missing]
    gitignore.write_text("\n".join([*lines, *block]).rstrip("\n") + "\n")

claude = Path("CLAUDE.md")
if claude.exists():
    text = claude.read_text()
    text = re.sub(
        r"the step-by-step is the `haywire-workflow` skill.*?`gh pr` command of any task\.\n",
        (template / "CLAUDE.workflow.md").read_text(),
        text,
        flags=re.S,
    )
    text = re.sub(
        r"A worktree goes beside the repositories \(`git worktree add \.\./[^`]+`\),\n\s*never elsewhere, "
        r"or the relative paths break\.",
        "A worktree can be anywhere: its setup (t3.json's *Worktree setup*) links core beside it.",
        text,
    )
    claude.write_text(text)
    if "haywire-dev" in text or "haywire-workflow" in text:
        print("note: CLAUDE.md still names haywire-dev or haywire-workflow; edit it by hand in the pull request")
PY

git add -A
if git diff --cached --quiet; then
  echo "$REPO already has the template's agent files."
  exit 0
fi
git diff --cached --stat
if ! $APPLY; then
  git --no-pager diff --cached
  echo
  echo "Preview only. Pass --apply to open the pull request."
  exit 0
fi

git commit --quiet -F - <<'MSG'
chore(agents): the organisation's agent files from going-haywire/.github

Every session in this repository and its worktrees gets core's workflow,
its hooks and the Farmhand bridge from committed files, with nothing to
install: .claude/settings.json runs core's hooks from ../haywire-repo,
.mcp.json starts the bridge, [tool.haywire.agents] names core's developer
docs, and t3.json sets up a worktree wherever T3 puts it
(going-haywire/haywire#212). The haywire-dev plugin is switched off here.
MSG
git push --quiet -u origin "$BRANCH"
gh pr create --repo "$REPO" --head "$BRANCH" --title "chore(agents): the organisation's agent files" --body \
  "The organisation's agent files from \`going-haywire/.github\`'s \`templates/library/\` (going-haywire/haywire#212): every session here and in its worktrees gets core's workflow page, its hooks and the Farmhand bridge from committed files, with nothing to install. Needs core's \`dev/\` from going-haywire/haywire#219 on core's \`master\`."

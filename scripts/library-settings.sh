#!/usr/bin/env bash
# Give one library repository the organisation's settings: squash merges only and
# branches deleted on merge, the rulesets in rulesets/library/, the intake's labels.
#
#   scripts/library-settings.sh going-haywire/haybale-<name>           # show what it would do
#   scripts/library-settings.sh going-haywire/haybale-<name> --apply   # do it
#
# Safe to run again: a ruleset of the same name is replaced, a label updated.
# Needs jq and gh, logged in as an admin of the repository. The PR gate requires the
# checks of the library's ci.yml (`ci / lint`, `ci / tests (ubuntu-24.04)`).
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
RULESETS=$(cd "$(dirname "$0")/.." && pwd)/rulesets/library

# step <description> <command...>: run the command with --apply, otherwise only name it.
step() {
  local what=$1
  shift
  if $APPLY; then
    "$@" >/dev/null
    echo "  done   $what"
  else
    echo "  would  $what"
  fi
}

[[ $(gh api "repos/$REPO" --jq .permissions.admin) == true ]] || {
  echo "this gh login is not an admin of $REPO" >&2
  exit 1
}
existing=$(gh api "repos/$REPO/rulesets" --jq '.[] | select(.source_type == "Repository") | [.name, .id] | @tsv')

echo "$REPO:"
step "merge settings: squash only, delete branch on merge" \
  gh api -X PATCH "repos/$REPO" \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true

for file in "$RULESETS"/*.json; do
  name=$(jq -r .name "$file")
  id=$(awk -F'\t' -v name="$name" '$1 == name { print $2 }' <<<"$existing")
  if [[ -n $id ]]; then
    step "ruleset \"$name\": replace ($id) with $(basename "$file")" \
      gh api -X PUT "repos/$REPO/rulesets/$id" --input "$file"
  else
    step "ruleset \"$name\": create from $(basename "$file")" \
      gh api -X POST "repos/$REPO/rulesets" --input "$file"
  fi
done

step 'label "needs introduction"' \
  gh label create "needs introduction" --repo "$REPO" --force --color FBCA04 \
  --description "PR from someone whose introduction is not accepted yet"
step 'label "agent files"' \
  gh label create "agent files" --repo "$REPO" --force --color D93F0B \
  --description "Changes files that steer agents or CI; the maintainer reads every line"

if $APPLY; then
  echo "Now:"
  gh api "repos/$REPO" --jq \
    '"  squash only: \(.allow_squash_merge and (.allow_merge_commit | not) and (.allow_rebase_merge | not)), delete branch on merge: \(.delete_branch_on_merge)"'
  gh api "repos/$REPO/rulesets" --jq \
    '.[] | select(.source_type == "Repository") | "  ruleset \(.id) \(.name) (\(.target), \(.enforcement))"'
else
  echo "Nothing changed. Run again with --apply to do it."
fi

# going-haywire/.github

What every repository of the going-haywire organisation shares. The library repositories
(`haybale-*`) take their community files from here. Core
([going-haywire/haywire](https://github.com/going-haywire/haywire)) keeps its own: they say
more than a library's (the whole contribution process, the studio's security scope, the
introduction form), and its process has to be in every clone, where people and agents read
it. GitHub shows a file from here only in a repository that has none of its own, and never
in a clone. The library files point to core's for what they share.

| Path | What | Used by |
|---|---|---|
| `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` | Org defaults: GitHub shows them in any repository that has no file of its own | library repositories |
| `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/` | Default pull request and issue templates | library repositories |
| `.github/workflows/library-ci.yml` | Reusable CI for a library: its tests against core `master` | each library's `ci.yml` and `nightly.yml` |
| `.github/workflows/pr-intake.yml` | Reusable intake: labels a pull request from its metadata | each library's `pr-intake.yml` |
| `.github/workflows/lint.yml` | This repository's own check: actionlint on the workflows, shellcheck on the scripts | this repository |
| `rulesets/library/`, `scripts/library-settings.sh` | A library's rulesets (*Permanent refs*, *Release tags*, *PR gate*) and the script that applies them, the merge settings and the intake's labels | the owner, once per library repository |
| `.claude-plugin/marketplace.json` | The Claude Code marketplace `going-haywire`: the `haywire-dev` plugin (a pointer to the workflow page and its hooks), taken from core's [`dev/`](https://github.com/going-haywire/haywire/tree/master/dev) on `master`; transitional until each library carries its own adapters (going-haywire/haywire#212) | each library's `.claude/settings.json` |

## Calling a reusable workflow

A library calls a workflow pinned to a commit of this repository, with the tag or date as a
comment, the same way every Action is pinned
([ADR 0080](https://github.com/going-haywire/haywire/blob/master/docs/adr/0080-untrusted-pull-requests-meet-nothing-with-power.md)).
Dependabot (`github-actions`) proposes the next commit.

```yaml
jobs:
  ci:
    uses: going-haywire/.github/.github/workflows/library-ci.yml@<commit> # 2026-11-18
```

A change here reaches a library only when that library moves its pin, in a pull request
where its own CI runs the new version first.

## A library repository's settings

The owner gives each library repository the same settings: squash merges only, branches
deleted on merge, three rulesets, and the labels the intake sets. From a clone of this
repository, logged in to `gh` as an admin of the library:

```sh
scripts/library-settings.sh going-haywire/haybale-<name>           # shows what it would do
scripts/library-settings.sh going-haywire/haybale-<name> --apply   # does it
```

It is safe to run again: a ruleset of the same name is replaced by the file's version.

| Ruleset | Holds |
|---|---|
| *Permanent refs* | The default branch is never deleted or force-pushed. No bypass. |
| *Release tags* | A `v*` tag is never deleted or moved. No bypass. |
| *PR gate* | The default branch changes only through a squash-merged pull request whose review threads are resolved and whose `ci / lint` and `ci / tests (ubuntu-24.04)` checks passed. Admins may merge a pull request without the checks (bypass mode `pull_request`), never push directly. |

The PR gate names the checks of the library's `ci.yml`, so the library calls
`library-ci.yml` from a job named `ci`.

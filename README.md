# going-haywire/.github

What every repository of the going-haywire organisation shares, the way GitHub distributes it:
community files it shows wherever a repository has none of its own, workflows other repositories
call, workflow templates, and the repository settings it applies. GitHub shows a file from here
only on its website, never in a clone; the text people and agents read lives in core's docs.

Core ([going-haywire/haywire](https://github.com/going-haywire/haywire)) takes every community file
from here except its issue templates: introductions are filed in core, so the introduction form
lives there, and the libraries' default issue templates link to it.

| Path | What | Used by |
|---|---|---|
| `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` | Org defaults: GitHub shows them in any repository that has no file of its own. `CONTRIBUTING.md` points to core's contributing page | every repository |
| `.github/pull_request_template.md` | Default pull request template | every repository |
| `.github/ISSUE_TEMPLATE/` | Default issue templates, linking to core's introduction form | library repositories |
| `.github/workflows/library-ci.yml` | Reusable CI for a library: its tests against core `master` | each library's `ci.yml` and `nightly.yml` |
| `.github/workflows/pr-intake.yml` | Reusable intake: labels a pull request from its metadata | each library's `pr-intake.yml` |
| `.github/workflows/lint.yml` | This repository's own check: actionlint on the workflows, shellcheck on the scripts | this repository |
| `workflow-templates/` | A library's CI callers (`ci.yml`, `nightly.yml`, `pr-intake.yml`) and its `dependabot.yml`. GitHub offers the callers under *Actions → New workflow*; core's `haywire init --org-files` writes all four into a library that lacks them, pinned to this repository's current commit | every library repository, once |
| `rulesets/library/`, `scripts/library-settings.sh` | A library's rulesets (*Permanent refs*, *Release tags*, *PR gate*) and the script that applies them, the merge settings and the intake's labels | the owner, once per library repository |

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

## A library repository's files

A library's repository files come from one command of core, run in the library:
`haywire init --org-files` (or `haywire init <name> --dev --org-files` for a new one). It writes
the CI callers and `dependabot.yml` from `workflow-templates/` here when the library lacks them
(once there, they are the library's own and Dependabot moves their pins), and the agent files from
core every time. Setting up a library repository, step by step: core's
[a new organisation library](https://going-haywire.github.io/haywire/docs/collaboration/new-org-library/).

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

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
| `.github/workflows/library-ci.yml` | Reusable CI for a library: its tests against core `master`, and again at its dependency floors (*The floors job*) | each library's `ci.yml` and `nightly.yml` |
| `.github/workflows/pr-intake.yml` | Reusable intake: labels a pull request from its metadata | each library's `pr-intake.yml` |
| `.github/workflows/lint.yml` | This repository's own check: actionlint on the workflows, shellcheck on the scripts | this repository |
| `workflow-templates/` | A library's CI callers (`ci.yml`, `nightly.yml`, `pr-intake.yml`) and its `dependabot.yml`. GitHub offers the callers under *Actions → New workflow*; core's `haywire init --org-files` writes all four into a library that lacks them, pinned to this repository's latest release | every library repository, once |
| `rulesets/library/`, `scripts/library-settings.sh` | A library's rulesets (*Permanent refs*, *Release tags*, *PR gate*) and the script that applies them, the merge settings and the intake's labels | the owner, once per library repository |

## Calling a reusable workflow

A library calls a workflow pinned to the commit of one of this repository's releases, with the
tag as a comment, the same way every Action is pinned
([ADR 0080](https://github.com/going-haywire/haywire/blob/master/docs/adr/0080-untrusted-pull-requests-meet-nothing-with-power.md)).
Dependabot (`github-actions`) follows the releases: its weekly pull request in each library moves
the pin to the next one.

```yaml
jobs:
  ci:
    uses: going-haywire/.github/.github/workflows/library-ci.yml@<commit> # v1.0.0
```

A change here reaches a library only when that library moves its pin, in a pull request
where its own CI runs the new version first.

### `library-ci.yml`'s inputs

| Input | Default | What |
|---|---|---|
| `python-version` | `'3.12'` | The Python the tests run on |
| `pytest-args` | `-q --maxfail=0` | The arguments after `pytest`, split as a shell would split them, for example `-m not(network)` |
| `system-packages` | `''` | apt packages a test needs on Linux, space-separated |
| `floors` | `true` | Run the *floors* job as well; `false` turns it off |

### The floors job

Next to `tests`, the `floors` job (check `ci / floors`) runs the same tests with every direct
requirement of the library at its floor, the oldest version it declares: core's
[ADR 0095](https://github.com/going-haywire/haywire/blob/master/docs/adr/0095-a-dependency-floor-is-the-oldest-version-known-to-work.md),
*a dependency floor is the oldest version known to work*. It runs on Linux only, wherever the
library calls `library-ci.yml` (every pull request, the default branch, the nightly), with the
same `pytest-args` and `system-packages`. A library has no browser tests here, so these are its
non-browser tests, as in core's own `floors` job.

- **Direct requirements** are those of the library's packages (`barn/*`), its development
  project and its dev group. A requirement without a floor (`numpy`) resolves to the oldest
  release on PyPI, which usually fails: give it one.
- **Core.** A library that reaches core by path tests its third-party floors against core
  `master`, whose own requirements stay at their newest. A library that installs core from PyPI
  tests its `haywire-core` floor too.
- **uv's two traps** (core's
  [.insights/project_uv_lowest_direct_relocks.md](https://github.com/going-haywire/haywire/blob/master/.insights/project_uv_lowest_direct_relocks.md)):
  the job sets `UV_RESOLUTION=lowest-direct` for every command, since a plain `uv run` would
  relock at highest, and syncs with `uv sync --upgrade`, since uv would keep the versions the
  committed lock holds. The run's summary lists the versions it installed.
- **Locally**, from the library:
  `UV_RESOLUTION=lowest-direct uv sync --upgrade --all-extras --dev && UV_RESOLUTION=lowest-direct uv run pytest`,
  then `git checkout uv.lock`.

### Releases

A release is a `vX.Y.Z` tag on `main`, made by the owner after a merge that changes what a
library runs: a reusable workflow or a workflow template. A patch for a fix, a minor version for
something new, a major one when a library's caller has to change too. The community files and
the rulesets need no release: GitHub reads the first from `main`, and `library-settings.sh`
applies the second.

```sh
git switch main && git pull --ff-only
git tag -a vX.Y.Z -m vX.Y.Z
git push origin vX.Y.Z
```

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

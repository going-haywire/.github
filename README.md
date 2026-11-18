# going-haywire/.github

What every repository of the going-haywire organisation shares. Core
([going-haywire/haywire](https://github.com/going-haywire/haywire)) carries its own copies of
the community files; the library repositories (`haybale-*`) take theirs from here.

| Path | What | Used by |
|---|---|---|
| `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` | Org defaults: GitHub shows them in any repository that has no file of its own | library repositories |
| `.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/` | Default pull request and issue templates | library repositories |
| `.github/workflows/library-ci.yml` | Reusable CI for a library: its tests against core `master` | each library's `ci.yml` and `nightly.yml` |
| `.github/workflows/pr-intake.yml` | Reusable intake: labels a pull request from its metadata | each library's `pr-intake.yml` |
| `.github/workflows/lint.yml` | This repository's own check: actionlint on the workflows | this repository |

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

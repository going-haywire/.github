# Contributing to a haywire library

Thanks for helping. The libraries of going-haywire (`haybale-*`) follow core's process:
roles, the introduction, issues before larger changes, pull requests from a fork, review
and the rules for agents are in core's
[CONTRIBUTING.md](https://github.com/going-haywire/haywire/blob/master/CONTRIBUTING.md).
This page holds only what differs in a library repository.

## Your first contribution

Introduce yourself once, in core:
[introduction](https://github.com/going-haywire/haywire/issues/new/choose). An introduction
accepted there counts for every repository of the organisation. A pull request that
arrives before it gets the label `needs introduction`; the label comes off the next time
the intake runs (a new push, or the maintainer re-running it) once the introduction is
accepted.

## Setting up

A library repository is a development project that reaches core by relative paths: clone
it beside a clone of core, under the names the paths expect.

```sh
gh repo clone going-haywire/haywire haywire-repo
gh repo fork going-haywire/<library> --clone
cd <library>
uv sync
```

Its `pyproject.toml` (`[tool.uv.sources]`) shows which core packages come from
`../haywire-repo`. A library without such sources installs core from PyPI. Running the
library in the full studio with other libraries: core's
[ADR 0081](https://github.com/going-haywire/haywire/blob/master/docs/adr/0081-libraries-from-other-repositories-run-from-an-umbrella-environment.md).

## Checks

```sh
uv run ruff check .
uv run ruff format --check .
uv run pytest
```

CI runs the same on every pull request, against core's `master`, and every night.

## Rules that are specific to libraries

- **Import the framework only through the Author API** (`haywire.api`,
  `haywire.api.workbench`); `ruff` refuses `haywire.core`, `haywire.ui` and `haywire.barn`
  outside the test fixtures.
- **A change that needs an unreleased change of core** raises that requirement's
  dependency floor (`>=`) to the next patch after core's latest release, in the same
  commit. CI runs against core's `master`, so it passes; the library is released once
  core is.
- **Never change a version number.** The maintainer releases a library through a release
  pull request (`haywire share --pr`); merging it publishes.
- **Files that steer agents or CI** (`CLAUDE.md`, `AGENTS.md`, `.mcp.json`, `.claude/`,
  `.github/`) get the label `agent files` until the maintainer has read every line.

## Licence, security, conduct

As in core: contributions are licensed under the repository's licence;
vulnerabilities go privately through [SECURITY.md](SECURITY.md); everyone follows the
[code of conduct](CODE_OF_CONDUCT.md).

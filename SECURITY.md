# Security policy

This policy covers every repository of going-haywire: core
([going-haywire/haywire](https://github.com/going-haywire/haywire)) and the libraries
(`going-haywire/haybale-*`).

## Reporting a vulnerability

Please report security problems privately, never in a public issue or pull request: use
*Report a vulnerability* on the *Security* tab of the repository concerned. If you are not
sure which repository it is, use
[core's](https://github.com/going-haywire/haywire/security/advisories/new). The report
reaches the maintainer only.

Include what you found, how to reproduce it, and the version or commit you tested. You
get an answer as soon as the maintainer has looked at it; a fix and a public advisory
follow once the problem is understood.

## Supported versions

Fixes go into the latest release of the repository concerned only. Core is released in
lockstep, so every package of a core release carries the same version.

## Scope

- **The studio** has a login, can be exposed to a network, and serves an MCP endpoint
  (Farmhand). Anything that lets someone reach, read or change a studio, its graphs or its
  machine without the access the studio's settings grant is in scope. How exposure,
  authentication and TLS are meant to work is described in
  [core's security guide](https://github.com/going-haywire/haywire/blob/master/docs/guides/security.md).
- **A library** runs inside the studio with the studio's rights, so anything in a library
  that does the same is in scope too.

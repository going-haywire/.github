# Security policy

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

Fixes go into the latest release of the repository concerned only.

## Scope

A library runs inside the studio with the studio's rights. Anything in a library that lets
someone reach, read or change a studio, its graphs or its machine without the access the
studio's settings grant is in scope, as are problems in core itself:
[core's security policy](https://github.com/going-haywire/haywire/blob/master/SECURITY.md).

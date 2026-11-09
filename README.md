# smtp-relay

Postfix that relays all mail through one authenticated upstream SMTP server,
published as `ghcr.io/jigfox/smtp-relay` (`linux/amd64`, `linux/arm64`).

Every release publishes `:X.Y.Z` and `:latest` (see "Development and
releases" below).

## Environment variables

| Variable | Required | Description |
| --- | --- | --- |
| `RELAY_HOST` | yes | Upstream SMTP server |
| `RELAY_PORT` | yes | Upstream port (e.g. `587`) |
| `RELAY_USER` | yes | Upstream SASL user |
| `RELAY_PASS` | yes | Upstream SASL password |
| `RELAY_NAME` | no | `myhostname` (default `localhost`) |
| `RELAY_NETS` | no | Clients allowed to relay (default `127.0.0.0/8 10.0.0.0/8 192.168.0.0/16`) |
| `RELAY_ALLOWED_SENDERS` | no | Comma-separated sender addresses or domains; when set, every other sender is rejected |
| `RELAY_SENDER_ACCESS_FILE` | no | Where the sender list is written (default `/etc/postfix/sender_access`) |
| `RELAY_SSL_PATH` | no | Directory with `server.crt` and `server.key`; enables TLS for clients |
| `RELAY_ENABLE_START_TLS` | no | With `RELAY_SSL_PATH`: also listen for submission on 587 |
| `RELAY_ENABLE_SMTPS` | no | With `RELAY_SSL_PATH`: also listen for SMTPS on 465 |

Port 25 is always open. Mail logs go to stdout.

## Development and releases

Changes reach `main` only through pull requests, merged with **rebase merge**
(every commit of the PR lands on `main` as it is). A PR needs green checks
(Lint, Build, Conventional commits) and an
up-to-date branch.

Every commit must be a [Conventional Commit](https://www.conventionalcommits.org)
(`type(scope): description`, `!` or a `BREAKING CHANGE:` footer for breaking
changes) with one of the types `feat`, `fix`, `perf`, `docs`, `test`,
`chore`, `ci`, `build`, `refactor`, `style` or `revert`, a header of at most
89 and a description of at most 72 characters. The rules are in
[`.conform.yaml`](.conform.yaml) and enforced by
[conform](https://github.com/siderolabs/conform); the check fails the PR
otherwise.

On every push to `main` the Release workflow looks at the commits since the
last `v*` tag and, if they warrant it, tags, builds and publishes a release
(multi-arch image `ghcr.io/jigfox/smtp-relay:<version>` and `:latest`
and generated release notes on the GitHub release; the first release is v1.0.0). If nothing
is releasable the workflow ends without a release.

| Commit type | Release |
| --- | --- |
| `feat` | minor |
| `fix`, `perf` | patch |
| breaking (`!` / `BREAKING CHANGE:`) | minor while the version is 0.x, major from 1.0 on |
| `docs`, `test`, `chore`, `ci`, `build`, `refactor`, `style` | none |

Renovate uses `fix(deps)` for the base image in the Dockerfile (it releases) and
`chore(deps)` for GitHub Actions and mise tools.

A PR from this repository (not a fork) with the label `prerelease` gets a
pre-release `v<next version>-pr.<PR number>.<run number>` on every push to the
branch: image tag and GitHub pre-release, never `:latest`. When the PR is
closed its pre-releases and tags are deleted (the images stay).

`mise install` also installs git hooks with lefthook (`lefthook.yml`): every
commit message is checked with conform on commit and every commit since
`origin/main` on push, with the same rules as CI.

The same logic runs locally (release versions by git-cliff, configured in
`cliff.toml`; commit rules by conform):

```sh
mise run release:next             # next version, empty if nothing is releasable (--or-patch: at least a patch)
mise run release:notes -- 1.2.0   # release notes of the unreleased commits
mise run commits:check            # all commits in origin/main..HEAD allowed by conform? (optional base branch argument)
mise run lint                     # shellcheck, hadolint, actionlint and zizmor
mise run docker:build             # build the image locally (IMG)
mise run docker:buildx            # build and push a multi-arch image (IMG required)
```

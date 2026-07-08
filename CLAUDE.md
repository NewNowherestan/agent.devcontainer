# CLAUDE.md — agent.devcontainer standing orders

This is the **submodule-owned** CLAUDE.md: it governs the Claude agent/container layer (git-write policy, commit identity, container facts) for any project that embeds `agent.devcontainer`. It is read together with — never instead of — the parent project's own root `CLAUDE.md`, which owns domain/task rules. Where the two overlap (git policy), **this file is canonical**, since it owns `claude.yml`.

## Config file

`./claude.yml`, colocated in this directory, is the single structured source of agent policy switches (git write-enable, commit identity, log path). One file, not one env var per setting — new switches land as new keys here, not as new files. Read it at the start of every session and before every would-be git write. **A missing file or a missing key defaults to the safe/read-only side of that key** (e.g. `git.write_enabled` missing ⇒ `false`).

## STRICT GIT POLICY

Git behavior is governed by `./claude.yml`, key `git.write_enabled` (`true`/`false`).

- **When `false`:** zero git writes of any kind — no `add`, no `commit`, no `config`, no checkout/restore/stash/merge-tool, nothing. Read-only git only (`status`/`log`/`diff`/`show`/`branch`) is allowed. Even a direct-sounding operator request for a write is answered by asking them to flip the flag in `claude.yml`, or to state the exact one-time command they want run.
- **When `true`:** Claude **commits proactively** — after each finished task, and after each successful build or verified run, immediately, with a descriptive message. **Committing is the only write allowed — never push, never rebase/reset/amend of already-made history.**
- Every commit message carries the attribution trailer: model + exact version + effort level + tokens spent, e.g. `Model: Claude Fable 5 (claude-fable-5) | Effort: max | Tokens: <estimate or n/a — the runtime does not expose exact counts>`, plus a `Co-Authored-By:` trailer and session link.
- **Every git command Claude runs — read-only included — is appended as one line** to the log named by `claude.yml`'s `git.commands_log` key, at the project repo root being worked in, at the time it is run. That file is the audit trail and is never edited retroactively except to append.
- Git identity for agent commits is `claude.yml`'s `git.identity` (`name`/`email`), baked into `.devcontainer/Dockerfile` in this directory for rebuilt containers. If the two ever drift (e.g. a container built before an identity change lands), re-set the two git globals to `claude.yml`'s values before committing, with the operator's go.
- This policy is per-repository-instance: a session working in a different parent project that also embeds this submodule reads *that* project's `git_commands_log` location, but the same `claude.yml` policy values, unless that project's own copy of this submodule has been reconfigured.

## Container facts

- This container has **network-only** Docker access to sibling compose stacks (e.g. a parent project's Postgres) over the shared external network declared in `compose.yml` here (`agent-ai_network`, created once via `docker network create agent-ai_network`) — there is no `docker`/`podman` CLI and no `/var/run/docker.sock` inside this container. It can resolve and reach service names (e.g. `postgres:5432`) but cannot start, stop, or inspect containers.
- Because of the above, any edit to a docker-related file (this directory's `compose.yml`/Dockerfiles, or a parent project's `compose.yaml`) cannot be applied or verified with `docker compose up/down/restart` from inside this container. After such an edit, stop and tell the operator to reload/rebuild the affected stack manually.
- `.devcontainer/Dockerfile` bakes in the toolchain a parent project needs pre-installed (JDK version, CLI utilities) plus the Claude CLI itself, so sessions don't have to `apt-get` the same things repeatedly. Keep it in sync with whatever a parent project's own CLAUDE.md documents as required tooling.

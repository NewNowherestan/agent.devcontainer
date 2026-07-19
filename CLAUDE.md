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

## THE LIVENESS RULE — long-running processes (2026-07-19, UDO-directed; a MAIN rule for every project embedding this submodule)

Launching anything long-running — a build, a soak run, a background process, a choreography
script, an external job — is incomplete until **three things are defined and armed at launch
time**:

1. **The outcome signal** — what "finished" looks like (exit code, final log line, artifact).
2. **The progress signal** — at least one observable that MUST move while the work is healthy
   (a log-line pattern, a row timestamp, a counter, a growing file), with its expected interval
   stated ("one retry line per minute", "a heartbeat row every 60s").
3. **The interval check** — a watcher/timer polling the progress signal on that interval
   (Monitor/watchdog/scheduled check — whatever the harness offers), armed alongside the
   outcome wait, never instead of it. Expect a mid-process result, not only an outcome.

**Silence discipline:** if the progress signal hasn't moved within ~2× its expected interval,
the process is presumed **stalled** — investigate immediately (process alive *and not a
zombie*? log advancing? port open? dependency up?), never keep waiting on the outcome timer
alone. Liveness checks must be state-aware: a `<defunct>` process passes `kill -0` — check
`ps -o stat=` (state `Z` = dead), not bare pid existence.

**Choreography scripts must EMIT timestamped progress events** (one line per completed step)
and carry **per-step deadlines** that emit a loud TIMEOUT event instead of looping forever —
a silent script is a stalled script by definition.

Origin (2026-07-19, Ippodromo DRAY-T29 verify): a proxy launched with a runtime absent from
the container died instantly and silently; the wait watched only the outcome signal and looked
"in progress" for 14 minutes; the retry watchdog then trusted `kill -0` on a zombie pid. Both
failure modes are exactly what the three-part launch contract prevents.

## Container facts

- This container has **network-only** Docker access to sibling compose stacks (e.g. a parent project's Postgres) over the shared external network declared in `compose.yml` here (`agent-ai_network`, created once via `docker network create agent-ai_network`) — there is no `docker`/`podman` CLI and no `/var/run/docker.sock` inside this container. It can resolve and reach service names (e.g. `postgres:5432`) but cannot start, stop, or inspect containers.
- Because of the above, any edit to a docker-related file (this directory's `compose.yml`/Dockerfiles, or a parent project's `compose.yaml`) cannot be applied or verified with `docker compose up/down/restart` from inside this container. After such an edit, stop and tell the operator to reload/rebuild the affected stack manually.
- `.devcontainer/Dockerfile` bakes in the toolchain a parent project needs pre-installed (JDK version, CLI utilities) plus the Claude CLI itself, so sessions don't have to `apt-get` the same things repeatedly. Keep it in sync with whatever a parent project's own CLAUDE.md documents as required tooling.

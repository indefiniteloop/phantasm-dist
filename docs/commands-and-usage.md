# Phantasm Commands And Usage

This page collects the current public CLI commands and the most
common ways to use them.

## Command Summary

Phantasm currently exposes four user-facing entry points:

```bash
phantasm --help
phantasm --version
phantasm bootstrap [project-path] [--agent-guidance] [--agent-file <path>]
phantasm handle-request '<json request envelope>'
```

`bootstrap` is the normal setup command.

`handle-request` is the advanced runtime command used by wrappers,
integrations, and direct testing.

## `phantasm --help`

Shows the built-in command summary, examples, and the full current
MVP `handle-request` operation surface.

Example:

```bash
phantasm --help
```

What it includes:

- the public CLI entrypoints
- the current `bootstrap` options
- the full supported `handle-request` operations list
- example command lines for users, wrappers, and advanced operators

## `phantasm --version`

Prints the installed version.

Example:

```bash
phantasm --version
```

## `phantasm bootstrap`

Sets up Phantasm for one project. Run this from the project root or
pass the target path explicitly.

Examples:

```bash
phantasm bootstrap
phantasm bootstrap .
phantasm bootstrap /path/to/project
```

What it creates:

```text
.phantasm/
├── phantasm.toml
├── clients.toml
└── state/
    ├── store.sqlite
    ├── backups/
    ├── indexes/
    ├── logs/
    ├── raw/
    └── tmp/
```

The generated config files are documented in
[configuration-reference.md](/Volumes/Files/Sojournings/Projects/phantasm/docs/configuration-reference.md).

### Agent guidance options

You can ask bootstrap to add a managed Phantasm guidance block to
agent instruction files.

Examples:

```bash
phantasm bootstrap . --agent-guidance
phantasm bootstrap . --agent-file AGENTS.md
phantasm bootstrap . --agent-file AGENTS.md --agent-file CLAUDE.md
```

Behavior:

- `--agent-guidance` scans common files such as `AGENTS.md`,
  `CLAUDE.md`, `Agents.md`, and `Claude.md`
- if none are present, it creates `AGENTS.md`
- the Phantasm block is managed and replaced idempotently on
  repeated runs
- `--agent-file` targets specific files explicitly and also enables
  guidance mode
- before writing anything, Phantasm prompts for confirmation with a
  `y/N` question in the terminal

## `phantasm handle-request`

Executes one JSON request envelope against the project in the
current working directory.

Example health check:

```bash
phantasm handle-request '{"api_version":"v1","operation":"health","request_id":"health-1","client":{"profile":"codex"},"params":{}}'
```

Important rule:

- run this from the project root you bootstrapped, or it will not
  find the correct `.phantasm/` directory

## Common Workflows

### First-time project setup

```bash
cd /path/to/project
phantasm bootstrap
phantasm handle-request '{"api_version":"v1","operation":"health","request_id":"health-1","client":{"profile":"codex"},"params":{}}'
```

Expected result:

- `bootstrap` creates `.phantasm/`
- `health` returns JSON with `"status":"ok"`

### Add agent instructions during setup

```bash
cd /path/to/project
phantasm bootstrap --agent-guidance
```

This updates existing supported agent files or creates `AGENTS.md`
if none are found.

You must confirm the write in the terminal before Phantasm changes
the file.

### Use one installed binary across many projects

```bash
phantasm --version
cd /project-one && phantasm bootstrap
cd /project-two && phantasm bootstrap
```

Each project gets its own `.phantasm/` state directory.

## Runtime Operations Through `handle-request`

The current runtime supports these operations:

- `bootstrap`
- `ingest`
- `revise`
- `tombstone`
- `archive`
- `promote`
- `resolve_conflict`
- `accept_suggestion`
- `reject_suggestion`
- `defer_review`
- `resolve_review`
- `search`
- `compile`
- `inspect`
- `audit`
- `review_queue`
- `health`
- `snapshot_export`
- `snapshot_import`
- `backup_list`
- `backup_restore`
- `maintenance_plan`
- `maintenance_run`

This is the same MVP operation set now shown by `phantasm --help`.

## Troubleshooting

`health_blocking` after a request:

- you are probably not in a bootstrapped project directory
- run `phantasm bootstrap` in the project root first

Agent guidance did not update the file you expected:

- use `--agent-file <path>` for an explicit target
- the automatic scan only covers the common markdown-style agent
  files

Need deeper runtime examples:

- use [user-setup-guide.md](/Volumes/Files/Sojournings/Projects/phantasm/docs/user-setup-guide.md) for the simplest install path
- use [configuration-reference.md](/Volumes/Files/Sojournings/Projects/phantasm/docs/configuration-reference.md) for every supported post-bootstrap config key

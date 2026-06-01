# Phantasm Commands And Usage

This page collects the current public CLI commands and the most
common ways to use them.

## Command Summary

Phantasm currently exposes five user-facing entry points:

```bash
phantasm --help
phantasm --version
phantasm bootstrap [project-path] [--agent-guidance] [--agent-file <path>]
phantasm agents --add [project-path] [--agent-file <path>]
phantasm handle-request '<json request envelope>'
```

`bootstrap` is the normal setup command.

`handle-request` is the advanced runtime command used by wrappers,
integrations, and direct testing.

## `phantasm --help`

Shows the built-in command index in the same command-oriented style as
`br --help`.

Example:

```bash
phantasm --help
phantasm help agents
phantasm agents --help
```

What it includes:

- the public CLI entrypoints
- a short description for each top-level command
- `help <command>` and `<command> --help` discovery for command-specific
  usage and options

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
- existing files are copied to timestamped sibling backup files before
  Phantasm changes them

## `phantasm agents --add`

Adds or refreshes managed Phantasm guidance without bootstrapping the
project again.

```bash
phantasm agents --add
phantasm agents --add /path/to/project
phantasm agents --add --agent-file AGENTS.md --agent-file CLAUDE.md
```

With no `--agent-file`, the command scans the same common files as
`bootstrap --agent-guidance`. Existing files receive timestamped sibling
backups before edits. The managed block tells agents to invoke Phantasm
memory workflows sequentially rather than running `handle-request`
processes in parallel.

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

### Add or refresh agent instructions

```bash
cd /path/to/project
phantasm agents --add
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

These operations remain available through `handle-request`. Use the
request API documentation when integrating them.

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

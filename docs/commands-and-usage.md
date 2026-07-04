# Phantasm Commands And Usage

This page collects the current public CLI commands and the most
common ways to use them.

For release-based changes, see [changelog.md](changelog.md).

## Command Summary

Phantasm exposes the same command surface through either `phantasm` or
the shorthand `phm` binary:

```bash
phantasm --help
phm --help
phantasm --version
phm --version
phantasm bootstrap [project-path] [--agent-guidance] [--agent-file <path>]
phantasm agents --add [project-path] [--agent-file <path>]
phantasm list [--kind <kind>] [--settled]
phantasm show <id>
phantasm search "query"
phantasm add --kind decision --subject release-process [--text "..."] [--review]
phantasm stats
phantasm status
phantasm handle-request '<json request envelope>'
phantasm handle-request --stdin
phantasm handle-request --file request.json
```

`bootstrap` is the normal setup command.

The human memory commands wrap the runtime API for common terminal
workflows: `list`, `show`, `search`, `add`, `stats`, and `status`.

`handle-request` is the advanced runtime command used by wrappers,
integrations, and direct testing.

## `phantasm --help`

Shows the built-in command index in the same command-oriented style as
`br --help`.

Example:

```bash
phantasm --help
phm --help
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
phm --version
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

After updating Phantasm, rerun `phantasm agents --add` to refresh the
managed guidance block in place. Do not delete and re-add the block
manually. Text outside the managed Phantasm markers is preserved; manual
edits inside the managed block are replaced by the current generated
guidance.

## Human memory commands

These commands are convenience wrappers over the same project runtime
used by `handle-request`.

```bash
phantasm list
phantasm list --kind decision
phantasm list --settled
phantasm show rec_example
phantasm search "release process"
phantasm add --kind decision --subject release-process
phantasm add --kind decision --subject release-process --text "Release from main after tests pass." --review
phantasm stats
phantasm status
```

`list` and `search` print compact rows with record id, kind, lifecycle
state, subject, and payload summary. `show` expands one object id.
`stats` prints record counts, lifecycle state counts, scope counts,
review queue size, and timestamps. `status` combines health, counts,
schema version, and recommended maintenance. `add` creates a memory
record; use `--review` when the write should enter review instead of
becoming authoritative immediately.

## `phantasm handle-request`

Executes one JSON request envelope against the project in the
current working directory.

Example health check:

```bash
phantasm handle-request '{"api_version":"v1","operation":"health","request_id":"health-1","client":{"profile":"codex"},"params":{}}'
```

Safer input modes are available when shell quoting or argv size is a
problem:

```bash
printf '%s' '{"operation":"describe","params":{"target":"ingest"}}' | phantasm handle-request --stdin
phantasm handle-request --stdin
phantasm handle-request --file request.json
```

Request input must be valid UTF-8. JSON strings round-trip printable
Unicode safely and accept standard escapes including `\uXXXX` surrogate
pairs.

Machine-readable API discovery:

```bash
phantasm handle-request '{"operation":"describe","params":{"target":"ingest"}}'
phantasm handle-request '{"operation":"describe","params":{"target":"all"}}'
phantasm handle-request '{"operation":"describe","params":{"target":"*"}}'
```

Complete describe targets also include machine-readable `cli` and
`request_transport` metadata: the `phm` alias, accepted input modes,
UTF-8 requirement, Unicode escape policy, and sequential execution rule.
They also document the `notices` response field and release update
notice shape.

Important rule:

- run this from the project root you bootstrapped, or it will not
  find the correct `.phantasm/` directory
- use `phantasm help handle-request` for the built-in copy of the
  operation catalog
- run requests sequentially against a project; do not run parallel
  `handle-request` mutations

### Request envelope

Every runtime operation uses the same envelope:

```json
{
  "api_version": "v1",
  "operation": "health",
  "request_id": "health-1",
  "client": {
    "profile": "codex",
    "session_id": "optional-session-id",
    "name": "optional-client-name",
    "version": "optional-client-version"
  },
  "params": {}
}
```

Required fields:

- `api_version`: current value is `v1`
- `operation`: one of the operation names in the catalog below
- `request_id`: caller-generated tracing ID
- `client.profile`: profile from `.phantasm/clients.toml`
- `params`: operation-specific object; use `{}` when no params are
  needed

Mutation fields:

- `idempotency_key`: required for mutating operations unless the request
  is a preview-only `params.dry_run=true` call
- `confirmations`: required for `resolve_conflict`,
  `snapshot_import`, `backup_restore`, and `maintenance_run`; include
  `approved_by`, `reason`, `operation`, and matching `target`. Dry-run
  previews skip confirmation because they do not mutate runtime state.

Every response includes a `notices` array. After a Phantasm binary
update, the first successful request for each project/client profile
returns a structured `release_update` notice with version, highlights,
breaking changes, and recommended agent action. Later calls suppress it
until the installed version changes again.

Read-only operations:

- `describe`, `templates`, `search`, `compile`, `inspect`, `audit`,
  `review_queue`, `health`, `backup_list`, `maintenance_plan`

Mutating operations:

- `bootstrap`, `ingest`, `ingest_many`, `revise`, `tombstone`,
  `tombstone_many`, `archive`, `promote`, `resolve_conflict`,
  `accept_suggestion`, `reject_suggestion`, `defer_review`,
  `resolve_review`, `snapshot_export`, `snapshot_import`,
  `backup_restore`, `maintenance_run`

### Agent-oriented examples

Ask Phantasm for the complete machine-readable API schema:

```bash
phantasm handle-request '{"operation":"describe","params":{"target":"all"}}'
phantasm handle-request '{"operation":"describe","params":{"target":"*"}}'
```

Ask Phantasm how to use one operation:

```bash
phantasm handle-request '{"operation":"describe","params":{"target":"ingest"}}'
```

Search memory before making a change:

```bash
phantasm handle-request '{"api_version":"v1","operation":"search","request_id":"search-auth-timeout","client":{"profile":"codex"},"params":{"query":"auth timeout","filters":{"include_conflicts":true,"review_augmented_view":true}}}'
```

Compile focused memory for a task:

```bash
phantasm handle-request '{"api_version":"v1","operation":"compile","request_id":"compile-auth-timeout","client":{"profile":"codex"},"params":{"token_budget":1200,"focus_subjects":["auth.timeout"]}}'
```

Ask compile to explain selected and omitted candidates:

```bash
phantasm handle-request '{"api_version":"v1","operation":"compile","request_id":"compile-auth-timeout-explain","client":{"profile":"codex"},"params":{"token_budget":1200,"focus_subjects":["auth.timeout"],"explain":true}}'
```

List built-in memory templates:

```bash
phantasm handle-request '{"api_version":"v1","operation":"templates","request_id":"templates-1","client":{"profile":"codex"},"params":{}}'
```

Ingest a durable project decision:

```bash
phantasm handle-request '{"api_version":"v1","operation":"ingest","request_id":"ingest-auth-timeout","client":{"profile":"codex"},"idempotency_key":"ingest-auth-timeout-v1","params":{"record_kind":"decision","subject_key":"auth.timeout","payload":{"text":"Auth tokens expire after 15 minutes."},"provenance":{"source":"agent","reason":"captured during implementation"}}}'
```

Create an ingest suggestion for review instead of writing authoritative
memory immediately:

```bash
phantasm handle-request '{"api_version":"v1","operation":"ingest","request_id":"ingest-review-auth-timeout","client":{"profile":"codex"},"idempotency_key":"ingest-review-auth-timeout-v1","params":{"record_kind":"decision","subject_key":"auth.timeout","payload":{"text":"Auth tokens expire after 15 minutes."},"review_required":true}}'
```

Ingest multiple independent records with per-item idempotency:

```bash
phantasm handle-request '{"api_version":"v1","operation":"ingest_many","request_id":"ingest-auth-batch","client":{"profile":"codex"},"idempotency_key":"ingest-auth-batch-v1","params":{"items":[{"idempotency_key":"ingest-auth-timeout-v1","record_kind":"decision","subject_key":"auth.timeout","payload":{"text":"Auth tokens expire after 15 minutes."}},{"idempotency_key":"ingest-auth-issuer-v1","record_kind":"constraint","subject_key":"auth.issuer","payload":{"text":"Issuer validation is required."}}]}}'
```

Preview an ingest without writing runtime state:

```bash
phantasm handle-request '{"api_version":"v1","operation":"ingest","request_id":"ingest-auth-timeout-preview","client":{"profile":"codex"},"params":{"record_kind":"decision","subject_key":"auth.timeout","payload":{"text":"Auth tokens expire after 15 minutes."},"dry_run":true}}'
```

Inspect a returned object:

```bash
phantasm handle-request '{"api_version":"v1","operation":"inspect","request_id":"inspect-1","client":{"profile":"codex"},"params":{"record_id":"rec_example"}}'
```

Inspect the default project memory summary:

```bash
phantasm handle-request '{"api_version":"v1","operation":"inspect","request_id":"inspect-summary","client":{"profile":"codex"},"params":{}}'
```

Export a named snapshot:

```bash
phantasm handle-request '{"api_version":"v1","operation":"snapshot_export","request_id":"snapshot-1","client":{"profile":"codex"},"idempotency_key":"snapshot-before-large-refactor","params":{"export_name":"before-large-refactor"}}'
```

Run confirmed maintenance:

```bash
phantasm handle-request '{"api_version":"v1","operation":"maintenance_run","request_id":"maint-1","client":{"profile":"codex"},"idempotency_key":"maintenance-reparse-profiles","confirmations":{"approved_by":"Manoj","reason":"refresh profiles after config edit","operation":"maintenance_run","target":{"operations":["reparse_client_profiles"]}},"params":{"operations":["reparse_client_profiles"]}}'
```

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
the file. Existing files are backed up first. When a new Phantasm
version changes agent guidance, rerun this command to replace the
managed block in place while preserving surrounding content.

### Use one installed binary across many projects

```bash
phantasm --version
phm --version
cd /project-one && phantasm bootstrap
cd /project-two && phantasm bootstrap
```

Each project gets its own `.phantasm/` state directory.

## Runtime Operations Through `handle-request`

The current runtime supports the following operations. This section
documents the practical V1 shape implemented by the CLI today. The API
may grow additional optional fields over time, but these names and
core meanings are the stable integration surface.

### `describe`

Returns machine-readable API schema, operation params, safety rules,
and runnable examples in one response. Agents should use this when they
need to discover Phantasm without reading docs or hunting source
strings.

- Params: optional `target`
- `target` values: `all`, `*`, `api`, or any operation name such as
  `ingest`, `search`, or `maintenance_run`
- `all`, `*`, and `api` return the complete operation catalog/schema
- Complete targets also include `cli` and `request_transport` metadata
  for wrappers.
- Short request form supported:
  `{"operation":"describe","params":{"target":"ingest"}}`
- Mutating: no
- Requires existing runtime: no
- Agent use: first-call discovery and focused per-operation schema
  lookup

### `bootstrap`

Initializes or verifies the project runtime under `.phantasm/`.
Humans usually use top-level `phantasm bootstrap`; wrappers may call
this operation through `handle-request`.

- Params today: `{}`
- Mutating: yes
- Optional preview param: `dry_run`
- Requires `idempotency_key`: yes when called through `handle-request`,
  unless `dry_run=true`

### `templates`

Returns built-in templates for common memory record kinds, including
project identity, architectural decision, operational constraint, known
issue, release procedure, environment setup, and deferred task.

- Optional params: `template_id`
- Read-only: yes
- Runtime required: no
- Agent use: choose a structured `record_kind`, `subject_key`, payload,
  and provenance shape before calling `ingest`

### `ingest`

Creates new memory. Trusted client profiles create authoritative
records. Untrusted profiles create suggestions plus review items so a
human or trusted agent can review them later. Trusted callers may also
set `review_required=true` to force suggestion/review behavior when an
automatic ingest is not clearly low-risk or explicitly approved. Use
`revise`, not `ingest`, to update an existing record. A duplicate `subject_key`
ingest is refused while a live record exists and returns guidance that
points to `revise` with the existing record id.

- Required params: `record_kind`, `payload`
- Common params: `scope`, `subject_key`, `provenance`, `sensitivity`,
  `raw_evidence`, `dry_run`, `review_required`
- Mutating: yes
- Dry-run behavior: returns a no-write preview, including
  `would_create` or `would_update` for trusted profiles and
  suggestion-preview output for untrusted profiles
- Agent use: capture durable decisions, constraints, implementation
  facts, or evidence after confirming they are new project truth; set
  `review_required=true` for automatic or uncertain writes

### `ingest_many`

Creates multiple memory records in one request. Each item is processed
independently and carries its own `idempotency_key`, so replay safety is
tracked per item rather than only at the envelope level. Successful
items are not rolled back when another item fails.

- Required params: `items`
- Each `items[]` entry requires: `idempotency_key`, `record_kind`,
  `payload`
- Common item params: `scope`, `subject_key`, `provenance`,
  `sensitivity`, `raw_evidence`, `dry_run`, `review_required`
- Mutating: yes
- Batch result fields: `results`, `count`, `ok_count`, `error_count`,
  `replayed_count`
- Agent use: capture several independent facts in one request while
  preserving per-item replay and failure reporting

### `revise`

Creates a successor record and supersedes the target record.

- Required params: `target_record_id`, `payload`
- Common params: `provenance`, `sensitivity`, `raw_evidence`, `dry_run`
- Mutating: yes
- Agent use: replace stale memory without losing lineage

### `tombstone`

Retires a record because it should no longer be treated as truth.

- Required params: `record_id`
- Mutating: yes
- Optional preview param: `dry_run`
- Agent use: remove known-bad memory from ordinary use while keeping an
  audit trail

### `tombstone_many`

Retires multiple records in one request. Each `items[]` entry carries
its own `idempotency_key` and `record_id`, and successful items are not
rolled back if another item fails validation or transition.

- Required params: `items`
- Each `items[]` entry requires: `idempotency_key`, `record_id`
- Common item params: `reason`, `dry_run`
- Mutating: yes
- Batch result fields: `results`, `count`, `ok_count`, `error_count`,
  `replayed_count`
- Agent use: remove several invalid records from the default truth set
  together while keeping per-item auditability

### `archive`

Keeps a record for history and audit but excludes it from ordinary
search and compile.

- Required params: `record_id`
- Mutating: yes
- Optional preview param: `dry_run`
- Agent use: move no-longer-current but still useful context out of the
  default truth set

### `promote`

Promotes scoped memory into project-scoped authoritative memory while
preserving lineage.

- Required params: `source_record_id`
- Common params: `provenance`
- Mutating: yes
- Optional preview param: `dry_run`
- Agent use: turn branch/worktree-specific truth into project truth

### `resolve_conflict`

Chooses a winning live record from a conflict set and retires losing
records.

- Required params: `winner_record_id`, `loser_record_ids`
- Optional params: `loser_state`, default `superseded`
- Practical loser states: `superseded`, `archived`, `tombstoned`
- Mutating: yes
- Requires `idempotency_key`: yes
- Requires `confirmations`: yes
  `confirmations` must include `approved_by`, `reason`, `operation`,
  and `target`; `target` must match `winner_record_id`,
  `loser_record_ids`, and resolved `loser_state`.
- Optional preview param: `dry_run`; dry-run previews do not require
  confirmations
- Agent use: settle contradictory memory after human or trusted-agent
  decision

### `accept_suggestion`

Converts a pending suggestion into authoritative memory and resolves a
linked review item when present.

- Required params: `suggestion_id`
- Mutating: yes
- Optional preview param: `dry_run`
- Agent use: accept memory proposed by an untrusted profile

### `reject_suggestion`

Rejects a pending suggestion without creating authoritative memory.

- Required params: `suggestion_id`
- Mutating: yes
- Optional preview param: `dry_run`
- Agent use: discard proposed memory that is incorrect, irrelevant, or
  too weak

### `defer_review`

Marks a review item deferred until a condition is met.

- Required params: `review_item_id`, `wake_condition`
- Mutating: yes
- Optional preview param: `dry_run`
- Agent use: postpone review when the correct decision depends on
  future work

### `resolve_review`

Marks a review item resolved.

- Required params: `review_item_id`
- Mutating: yes
- Optional preview param: `dry_run`
- Agent use: close review work after the underlying conflict,
  suggestion, or maintenance concern was handled

### `search`

Finds memory records deterministically.

- Params: optional `query`, optional `match_mode` (`tokens` default,
  `exact`, or `fuzzy`), optional `rank_by` (`deterministic` or `relevance`), optional
  `group_by` (`record_kind`), optional `filters`
- Supported filters: `scope`, `include_superseded`,
  `include_archived`, `include_tombstoned`, `include_conflicts`,
  `include_sensitive`, `review_augmented_view`,
  `include_raw_evidence`, `branch_name`, `worktree_id`,
  `subject_key`, `record_kind`, `created_after`, `created_before`,
  `payload_contains`, `payload_matches`
- Mutating: no
- Agent use: look up prior decisions and constraints before editing

### `compile`

Builds a deterministic context payload for an agent.

- Params: optional `token_budget`, optional `focus_subjects`, optional
  `filters`
- Uses the same filter keys as `search`
- Mutating: no
- Agent use: gather concise project memory for the current task

### `inspect`

Returns full object details for specific IDs.

- Params: `record_id` or `record_ids`, `suggestion_id` or
  `suggestion_ids`, `review_item_id` or `review_item_ids`,
  `operation_id` or `operation_ids`, `evidence_id` or `evidence_ids`
- Mutating: no
- Agent use: expand an ID returned by search, compile, audit, or
  review_queue

### `audit`

Lists operation history and effect summaries.

- Params: optional `actor`, `object_id`, `operation_name`, `limit`,
  `cursor`
- Default limit: `50`
- Pagination: use `data.next_cursor` from one response as
  `params.cursor` on the next request to fetch older operations
- Mutating: no
- Agent use: understand who changed memory and what each operation
  affected

### `review_queue`

Lists open and deferred review items.

- Params today: `{}`
- Mutating: no
- Agent use: discover memory suggestions, conflicts, or operational
  concerns that need attention

### `health`

Reports runtime health, conflict count, live conflict subjects,
review count, failed maintenance count, profiles, diagnostics, and
recommended maintenance. It is the recommended first call after agent
startup because it can surface one-time `release_update` notices.

- Params today: `{}`
- Mutating: no
- Agent use: start-of-session health check

### `snapshot_export`

Writes a full runtime snapshot bundle under `.phantasm/state/backups/`
and registers it as a backup.

- Params: optional `export_name`
- Mutating: yes
- Requires `idempotency_key`: yes
- Optional preview param: `dry_run`
- Agent use: preserve state before a large refactor or risky runtime
  operation

### `snapshot_import`

Restores a snapshot bundle into the runtime after creating a safety
backup.

- Required params: `bundle_path`
- Optional params: `mode`; supported values are `replace` and `merge`
- Current merge behavior: restores the full bundle and returns a
  warning
- Mutating: yes
- Requires `idempotency_key`: yes
- Requires `confirmations`: yes
  `confirmations` must include `approved_by`, `reason`, `operation`,
  and `target`; `target` must match `bundle_path` and resolved `mode`.
- Optional preview param: `dry_run`; dry-run previews do not require
  confirmations

### `backup_list`

Lists registered backups and manifests.

- Params today: `{}`
- Mutating: no
- Agent use: find backup IDs before restore

### `backup_restore`

Restores a registered backup by ID after creating a safety backup.

- Required params: `backup_id`
- Mutating: yes
- Requires `idempotency_key`: yes
- Requires `confirmations`: yes
  `confirmations` must include `approved_by`, `reason`, `operation`,
  and `target`; `target` must match `backup_id`.
- Optional preview param: `dry_run`; dry-run previews do not require
  confirmations

### `maintenance_plan`

Dry-run planning surface for maintenance recommendations and required
backup actions.

- Params today: `{}`
- Mutating: no
- Agent use: see what maintenance would do before asking to run it

### `maintenance_run`

Records and executes explicit maintenance operations.

- Params: optional `operations` array
- Default operations: `["reparse_client_profiles"]`
- Creates a pre-maintenance backup when `backup_prune` is requested
- Mutating: yes
- Requires `idempotency_key`: yes
- Requires `confirmations`: yes
  `confirmations` must include `approved_by`, `reason`, `operation`,
  and `target`; `target` must match the resolved `operations` list.
- Optional preview param: `dry_run`; dry-run previews do not require
  confirmations

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

# Changelog

Phantasm changelog entries are version based. Each section describes
what ships in that release. Use concrete version headings rather than
placeholder holding sections.

## v0.2.2

These changes ship in the Phantasm v0.2.2 release.

### Added

- Added human-friendly memory CLI commands for routine workflows:
  `phantasm list`, `phantasm show <id>`, `phantasm search "query"`,
  `phantasm add --kind <kind> --subject <key>`, `phantasm stats`, and
  `phantasm status`.
- Added a default `inspect` summary when called without object IDs,
  including record counts, live/conflict counts, lifecycle state counts,
  scope counts, review item count, timestamp bounds, and compact live
  and conflict record lists.
- Added opt-in `compile.params.explain=true` diagnostics so callers can
  see why compile candidates were selected or omitted, including
  candidate rank, selection rank, token estimates, focus-subject
  influence, lifecycle state, and token-budget omission reasons.
- Added `ingest.params.review_required=true` so trusted callers can
  intentionally create suggestions and review items instead of direct
  authoritative memory for automatic or uncertain writes.
- Added `write_mode` to ingest dry-run responses so callers can confirm
  whether a request would write authoritative memory or queue a
  suggestion.
- Added a read-only `templates` operation with built-in templates for
  project identity, architectural decision, operational constraint,
  known issue, release procedure, environment setup, and deferred task
  records.
- Added `scripts/scale_test.sh`, a configurable scale harness covering
  sequential ingest, concurrent writers, search, compile, snapshot
  restore, and corrupt-snapshot recovery checks.

### Changed

- Updated `describe`, built-in help, managed agent guidance, public
  command docs, and the public site to document `review_required`,
  `compile.explain`, `templates`, the default `inspect` summary, and
  human-friendly memory commands.
- Updated internal operator documentation with quick and default scale
  test commands and guidance on when to run scale/recovery checks.

## v0.2.1

These changes shipped in the Phantasm v0.2.1 release.

### Added

- Added operation-specific CLI help for `handle-request` so callers can
  print a single operation schema and runnable example without sending a
  runtime request first.
- Added `params.dry_run` preview support for mutating operations. This
  lets callers inspect no-write outcomes such as `ingest`
  `would_create`/`would_update` results before risking collisions or
  writes to the wrong scope.
- Added payload fidelity metadata on write responses so callers can
  compare request bytes and hashes with the stored payload.
- Added mojibake detection warnings on write responses so UTF-8
  transport corruption is surfaced immediately instead of being silently
  persisted.

### Changed

- Updated unsupported operation validation errors to list all valid
  operation names and point callers to `describe target=all` or
  `target=*` for the full operation catalog.
- Updated required-field validation errors to be operation aware. They
  now include the missing or invalid `params.<field>`, the expected
  type, the required param set for that operation, the field
  description, a runnable example request, and a
  `describe target=<operation>` recovery hint.
- Updated `health` to expose grouped `live_conflict_subjects` alongside
  `live_conflict_count` so agents can identify affected
  `record_kind`/`subject_key` pairs without scanning audit history.
- Updated `live_conflict` lifecycle effect payloads to include the
  affected `record_id`, `record_kind`, and `subject_key` for faster
  recovery through the audit surface.
- Updated built-in help, operation schemas, and public/internal command
  references to document `dry_run` previews and the newer
  operation-specific help surface.

### Fixed

- Fixed snapshot bundle export to capture SQLite WAL-backed state
  atomically instead of risking inconsistent snapshot contents.
- Fixed raw-evidence attachment persistence to behave more defensively
  around write-time evidence storage.

## v0.2.0

These changes shipped in the Phantasm v0.2.0 release.

### Added

- Added `search.params.match_mode` values `tokens`, `exact`, and
  `fuzzy`, with token matching as the default for natural multi-term queries.
- Added `search.params.rank_by` with `deterministic` and `relevance`
  ordering modes.
- Added `search` match diagnostics with per-result scores, matched
  fields, and matched terms.
- Added `search.params.group_by=record_kind` aggregations with grouped
  counts and sample record IDs.
- Added `search.filters.payload_contains` and
  `search.filters.payload_matches` for payload substring and regex
  filtering.
- Added `search.filters.subject_key`, `record_kind`, `created_after`,
  and `created_before` for practical metadata filtering.
- Added `phm` as a shorthand CLI binary for the same command surface as
  `phantasm`.
- Added `phantasm handle-request --stdin` for request envelopes supplied
  through standard input.
- Added `phantasm handle-request --file <path>` for UTF-8 request
  envelope files.
- Added machine-readable `cli` and `request_transport` metadata to
  complete `describe` targets.
- Added top-level response `notices` metadata for all successful
  `handle-request` responses.
- Added first-call `release_update` notices after binary upgrades,
  scoped per bootstrapped project and client profile.
- Added project-local release notice seen state using
  `release_notice_seen.<client_profile>`.
- Added structured confirmation validation for high-impact operations.
  `resolve_conflict`, `snapshot_import`, `backup_restore`, and
  `maintenance_run` now require `approved_by`, `reason`, `operation`,
  and a `target` object matching the mutation request.
- Added duplicate `subject_key` ingest refusal so callers get the
  existing record id and clear `revise` guidance instead of accidentally
  creating conflicting truth.
- Added public and internal documentation for the `phm` alias, request
  input modes, response notices, release update notices, structured
  confirmations, ingest create-vs-update semantics, and release metadata
  maintenance.

### Changed

- Updated `describe` schemas, built-in help, public docs, and site docs
  to document search match modes, ranking, aggregations, and expanded
  filters.
- Updated `describe target=all|*|api` to document response metadata,
  `notices`, release update notice shape, CLI aliasing, and request
  transport options.
- Updated `health` guidance to make it a good first call after agent
  startup because it can surface one-time release notices.
- Updated built-in `help handle-request` with the `--stdin`,
  `--file <path>`, and `notices` behavior.
- Updated public install and usage docs to verify both `phantasm` and
  `phm`.
- Updated `ingest` schema, built-in help, public docs, site docs, and
  managed agent guidance to make it explicit that `ingest` creates new
  memory and `revise` updates existing memory.
- Updated conflict resolution examples to include the required
  structured confirmation payload.
- Updated release documentation to require reviewing embedded release
  notice metadata before tagging.

### Fixed

- Fixed JSON parsing for printable UTF-8 strings so non-ASCII text is
  preserved correctly.
- Fixed JSON `\uXXXX` escape handling, including valid surrogate pairs
  and invalid surrogate rejection.
- Fixed JSON string output so printable Unicode remains readable while
  control characters are still escaped.

## Earlier Releases

Earlier public releases established the initial local project memory
runtime, bootstrap flow, agent guidance management, JSON
`handle-request` API, operation catalog, SQLite-backed project state,
snapshots, backups, maintenance operations, and public install paths.

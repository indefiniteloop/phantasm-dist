# Changelog

Phantasm changelog entries are release based. Unreleased entries
describe changes queued for the next release; versioned entries describe
changes that have shipped.

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

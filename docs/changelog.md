# Changelog

Phantasm changelog entries are release based. Unreleased entries
describe changes queued for the next release; versioned entries describe
changes that have shipped.

## Unreleased

These changes are queued for the next Phantasm release and should be
moved under that release version when it is tagged.

### Added

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
- Added public and internal documentation for the `phm` alias, request
  input modes, response notices, release update notices, and release
  metadata maintenance.

### Changed

- Updated `describe target=all|*|api` to document response metadata,
  `notices`, release update notice shape, CLI aliasing, and request
  transport options.
- Updated `health` guidance to make it a good first call after agent
  startup because it can surface one-time release notices.
- Updated built-in `help handle-request` with the `--stdin`,
  `--file <path>`, and `notices` behavior.
- Updated public install and usage docs to verify both `phantasm` and
  `phm`.
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

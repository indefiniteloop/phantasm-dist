# Phantasm Configuration Reference

This reference documents every user-editable config option created by
`phantasm bootstrap`.

After bootstrap, the current shipped runtime creates exactly two
config files:

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

Only `phantasm.toml` and `clients.toml` are public config files
today. Everything under `state/` is runtime state, storage, or
derived output.

## `.phantasm/phantasm.toml`

Default file contents:

```toml
version = "v1"
default_client = "generic_mcp"
```

Supported keys:

- `version`
  Type: quoted string.
  Default: `"v1"`.
  Meaning: runtime config schema version.
  Supported values: only `"v1"` today.

- `default_client`
  Type: quoted string.
  Default: `"generic_mcp"`.
  Meaning: default client profile name for runtime consumers that rely
  on config rather than hard-coding a profile.
  Supported values: any profile name that exists in
  `.phantasm/clients.toml`.

Built-in profile names currently available:

- `generic_mcp`
- `dashboard`
- `codex`
- `claude_code`

## `.phantasm/clients.toml`

Default file contents:

```toml
version = "v1"

# User-defined profiles must inherit from exactly one built-in profile.
# Built-ins: generic_mcp, codex, claude_code, dashboard
#
# Example:
# [profiles.codex_readonly]
# inherits = "codex"
# display_name = "Codex Read Only"
# allow_authoritative_writes = false
```

The top-level file key is `version`. Custom profiles live inside
`[profiles.<name>]` sections.

### Top-level key

- `version`
  Type: quoted string.
  Default: `"v1"`.
  Meaning: client-profile schema version.
  Supported values: only `"v1"` today.

### Per-profile keys

Each custom profile section may contain these keys:

- `inherits`
  Type: quoted string.
  Required: yes.
  Meaning: the built-in profile this custom profile extends.
  Supported values: `generic_mcp`, `codex`, `claude_code`, or `dashboard`.

- `display_name`
  Type: quoted string.
  Required: no.
  Meaning: human-friendly label for the profile.
  Default behavior: if omitted, Phantasm derives the display name from
  the section name by replacing underscores with spaces.

- `allow_suggestions`
  Type: boolean.
  Required: no.
  Meaning: whether the profile may create suggestion-shaped runtime
  mutations.
  Default behavior: inherits from the selected built-in parent.

- `allow_authoritative_writes`
  Type: boolean.
  Required: no.
  Meaning: whether the profile may perform authoritative writes.
  Default behavior: inherits from the selected built-in parent.

- `allow_sensitive_read`
  Type: boolean.
  Required: no.
  Meaning: whether the profile may perform sensitive reads.
  Default behavior: inherits from the selected built-in parent.

- `allow_sensitive_export`
  Type: boolean.
  Required: no.
  Meaning: whether the profile may export sensitive data.
  Default behavior: inherits from the selected built-in parent.

## Built-in profile defaults

These built-ins ship in the runtime:

- `generic_mcp`
  `allow_suggestions = true`
  `allow_authoritative_writes = false`
  `allow_sensitive_read = false`
  `allow_sensitive_export = false`

- `codex`
  `allow_suggestions = true`
  `allow_authoritative_writes = true`
  `allow_sensitive_read = false`
  `allow_sensitive_export = false`

- `claude_code`
  `allow_suggestions = true`
  `allow_authoritative_writes = true`
  `allow_sensitive_read = false`
  `allow_sensitive_export = false`

- `dashboard`
  `allow_suggestions = true`
  `allow_authoritative_writes = true`
  `allow_sensitive_read = false`
  `allow_sensitive_export = false`

  The HTTP dashboard additionally restricts this profile to read operations
  and accept/reject/defer/resolve review actions.

## Example custom profile

```toml
version = "v1"

[profiles.codex_readonly]
inherits = "codex"
display_name = "Codex Read Only"
allow_authoritative_writes = false
```

This keeps the `codex` defaults for everything except authoritative
writes, which it turns off.

## Current limitations

- There is no supported config key for context length yet.
- There is no supported config key for token budget yet.
- There is no supported config key for model selection yet.
- Unknown keys inside a profile section are rejected as config errors.
- Values must use the expected quoted-string or boolean format.

If you were looking for a setting such as context length, the absence
is real: the current shipped runtime does not expose that knob after
bootstrap.

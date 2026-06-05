# Phantasm User Setup Guide

This guide is for someone who wants to use Phantasm without
building Rust code or reading the implementation.

## What Phantasm Does

Phantasm is a local memory runtime for AI coding agents. You
install the binary once on your machine, then turn it on for each
project you care about.

Phantasm stores its data inside each project, not in one giant
machine-wide database. That keeps projects separate and makes it
clear where the memory lives.

## Before You Start

You do not need Rust for the normal install path.

You do need:

- a macOS, Linux, or Windows machine
- permission to add a program to a user-level install directory
- a terminal or PowerShell window

## Install Phantasm

### macOS and Linux

If you want the easiest Unix setup path, use Homebrew.

First, check whether Homebrew is already installed:

```bash
brew --version
```

If that prints a Homebrew version, continue to the next step.

If it says `brew: command not found`, install Homebrew first.

On macOS, run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

On Linux, run:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After the Homebrew installer finishes:

1. Close and reopen your terminal if the installer tells you to.
2. Run `brew --version` again.
3. If `brew` still is not found, follow the PATH instructions printed
   by the Homebrew installer.

Then install Phantasm from the published tap:

```bash
brew install indefiniteloop/tap/phantasm
```

After that, verify the install:

```bash
phantasm --version
```

If you prefer the standalone installer, run:

```bash
curl -fsSL https://raw.githubusercontent.com/indefiniteloop/phantasm-dist/main/scripts/install.sh?utm_source=phatasm | sh
```

What this does:

- downloads the latest Phantasm release from the public
  `indefiniteloop/phantasm-dist` GitHub Releases page
- checks the release checksum
- installs `phantasm` into `~/.local/bin` by default
- prints a PATH hint if needed

Homebrew is the preferred Unix install path if it is already part of
your toolchain. The shell installer remains the fallback for systems
without Brew.

If you need a different GitHub repo or install directory:

```bash
curl -fsSL https://raw.githubusercontent.com/indefiniteloop/phantasm-dist/main/scripts/install.sh?utm_source=phatasm | sh -s -- --repo your-org/phantasm-dist --install-dir "$HOME/bin"
```

### Windows

Open PowerShell and run the installer script from the public
distribution repo, or download the latest Windows release asset and
extract `phantasm.exe` into a directory on your PATH.

If you have the installer script locally:

```powershell
./scripts/install.ps1
```

The default install location is:

```text
$HOME\AppData\Local\Programs\phantasm\bin
```

## Verify The Install

Run:

```bash
phantasm --version
```

You should see output like:

```text
phantasm 0.1.0
```

You can also inspect the built-in help:

```bash
phantasm --help
```

The help output lists top-level commands. Use command-specific help for
options:

```bash
phantasm agents --help
phantasm help bootstrap
phantasm help handle-request
```

## Turn Phantasm On For A Project

Phantasm must be set up once inside each project you want it to
manage.

In your project directory, run:

```bash
cd /path/to/your/project
phantasm bootstrap
```

That creates a `.phantasm/` directory inside the project.

If you also want repository agent instruction files to mention
Phantasm automatically, run:

```bash
phantasm agents --add
```

Phantasm will ask for confirmation before it appends or creates any
agent file content. Reply `y` or `yes` to continue. Before changing an
existing agent file, it creates a timestamped sibling backup.

To target specific files instead of scanning common agent filenames:

```bash
phantasm agents --add --agent-file AGENTS.md --agent-file CLAUDE.md
```

## What `bootstrap` Creates

After bootstrap, your project gets:

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

This is the project-local runtime data for Phantasm.

For every supported key in `phantasm.toml` and `clients.toml`, use
[configuration-reference.md](/Volumes/Files/Sojournings/Projects/phantasm/docs/configuration-reference.md).

## Use Across Agents And Projects

Use across projects:

1. Install `phantasm` once on your machine.
2. In each project, run `phantasm bootstrap`.
3. Point your integrations or wrappers at the same installed
   `phantasm` binary.

Use across agents:

- multiple agents can use the same installed binary
- each project still needs its own `.phantasm/` bootstrap
- agent integrations should run in the project directory so
  Phantasm can find the right `.phantasm/` folder

## Important Limitation Right Now

The current binary does **not** yet expose a dedicated end-user MCP
stdio server command such as `serve`.

Today, the public user-facing setup command is:

```bash
phantasm bootstrap
```

The advanced integration command is:

```bash
phantasm handle-request '<json request envelope>'
```

Agents and wrappers can ask Phantasm for the complete machine-readable
runtime API before they know any operation-specific schema:

```bash
phantasm handle-request '{"operation":"describe","params":{"target":"all"}}'
phantasm handle-request '{"operation":"describe","params":{"target":"*"}}'
phantasm handle-request '{"operation":"describe","params":{"target":"ingest"}}'
```

`describe` is read-only, does not require an existing project runtime,
and returns request envelope rules, operation params, idempotency and
confirmation requirements, safety guidance, and runnable examples.
Use `target="all"` or `target="*"` for the complete operation catalog,
`target="api"` for the complete API schema, and an operation name such
as `ingest` for a focused schema.

That means:

- if a tool expects a ready-made MCP server executable, you may need
  a wrapper or adapter
- if you are just preparing projects and installing the runtime, the
  steps in this guide are still the correct first setup

## Troubleshooting

`phantasm: command not found`

- add the install directory to your PATH
- on macOS/Linux the default is `~/.local/bin`
- restart the terminal after updating PATH

`brew: command not found`

- Homebrew is not installed yet, or its PATH setup did not finish
- run the Homebrew install command shown earlier in this guide
- reopen the terminal and run `brew --version`
- if needed, apply the PATH commands printed by the Homebrew installer

`unknown client profile`

- the project may be missing `.phantasm/clients.toml`
- run `phantasm bootstrap` again from the project root

Phantasm works in one project but not another

- you likely forgot to run `phantasm bootstrap` in the second project
- or you are running the integration from the wrong working
  directory

Install script cannot find a release

- confirm the repository slug is correct
- try the installer with `--repo your-org/your-repo` if you are
  using a fork
- confirm the public distribution repo has published GitHub Releases,
  not only CI workflow artifacts

Homebrew install cannot find the formula

- confirm you ran `brew install indefiniteloop/tap/phantasm`
- run `brew update` and retry
- if you maintain a fork, publish a matching tap repo and install from
  that owner instead

## Manual Install For Advanced Users

If you prefer not to use the installer script:

1. Download the correct archive from the public
   `indefiniteloop/phantasm-dist` GitHub Releases page.
2. Verify it against the published `SHA256SUMS` file.
3. Extract the binary.
4. Place `phantasm` or `phantasm.exe` in a directory on your PATH.
5. Run `phantasm --version`.
6. Run `phantasm bootstrap` inside each project you want to use.

## Next Step

Once Phantasm is installed and your project has been bootstrapped,
use the agent or integration you prefer and make sure it runs from
that project directory.

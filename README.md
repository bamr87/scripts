# 🛠️ scripts

A standalone collection of Bash command-line utilities (plus one Python tool) for project bootstrapping, GitHub repository management, and multi-repo maintenance.

There is no application to build and no dependency install — every script is self-contained and runs directly. This repo is also vendored as a submodule of the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87), which installs several of these scripts as named CLI commands (see [Installation](#-installation)).

## 📦 Tool index

| Script | Command | What it does |
| --- | --- | --- |
| [`project-init.sh`](project-init.sh) | `project-wizard` | Interactive/non-interactive project scaffolding wizard — Django, React, Node, Python, Rust, Go, custom; optional Docker, CI, license, and GitHub repo creation |
| [`forkme.sh`](FORKME/forkme.sh) → `FORKME/forkme.sh` | `forkme` | Repository forking/cloning utility with 10 strategies (full, shallow, sparse, toplevel, structure, filetype, analysis, mirror, bundle, metadata-only) |
| [`STASHME/stashme.sh`](STASHME/stashme.sh) | `stashme` | Multi-repo cloud stash — pushes uncommitted work across many repos to timestamped `stashme/…` backup branches, with restore and cleanup modes |
| [`git_init.sh`](git_init.sh) | `git-init` | Interactive/headless git + GitHub repo creator; prefers `gh`, falls back to `npx degit` for templates, uses gitignore.io for `.gitignore` |
| [`rename-directory.sh`](rename-directory.sh) | `rename-dir` | Safe directory rename with git/Docker pre-flight checks and optional backup |
| [`create_package.sh`](create_package.sh) | `create-package` | Bootstraps a Python package repo from `microsoft/python-package-template` |
| [`tools/unwrap-prose.py`](tools/unwrap-prose.py) | — | Liquid-safe markdown unwrapper enforcing one-paragraph-per-line; backs the `markdown-oneline` CI gate |

Per-tool deep dives live next to the tools: [`FORKME/`](FORKME/FORKME.md), [`STASHME/`](STASHME/STASHME.md), and [`RENAME-DIRECTORY-QUICK-REFERENCE.md`](RENAME-DIRECTORY-QUICK-REFERENCE.md).

## 🚀 Installation

There are two ways to get these tools on your `PATH`, and which one you want depends on whether you also use the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87).

**If you have the dash checked out**, use its bootstrap — do *not* run `install.sh`. `tools/setup.sh` in the hub marks every `*.sh` here executable and symlinks the full set into `~/.local/bin` as `forkme`, `stashme`, `git-init`, `project-wizard`, `rename-dir`, and `create-package`:

```bash
cd /path/to/bamr87        # the hub checkout
./tools/setup.sh          # or: ./tools/setup-dev.sh
```

**If you only have this repo**, use the standalone installer. It is narrower on purpose — it wires up the Project Initialization Wizard only (`project-wizard`), creates `~/.project-wizard/`, appends `~/.local/bin` to your shell `PATH`, and drops a copy of `env.example` for you to customize:

```bash
git clone https://github.com/bamr87/scripts.git
cd scripts
./install.sh
source ~/.zshrc          # or ~/.bashrc
```

Running both is harmless (the symlinks are idempotent), but redundant — the hub's setup is a strict superset for CLI installation.

Every script also runs directly with no installation at all:

```bash
./project-init.sh --help
./forkme.sh --help
./STASHME/stashme.sh --dry-run
```

## 🎯 Quick start

### Project Initialization Wizard

Interactive mode walks you through project type, name, GitHub settings, optional features (Docker, CI/CD), and license:

```bash
./project-init.sh
```

Non-interactive mode takes environment variables or flags:

```bash
# Environment variables
PROJECT_TYPE=django PROJECT_NAME=my-api SETUP_DOCKER=true SETUP_CI=true \
  ./project-init.sh --non-interactive

# Command-line arguments
./project-init.sh --type react --name my-react-app --dir ~/projects/my-react-app
```

Copy [`env.example`](env.example) to `.env` to set your own defaults. Key options:

| Variable | Description | Options |
| --- | --- | --- |
| `PROJECT_TYPE` | Type of project to create | `django`, `react`, `node`, `python`, `rust`, `go`, `custom` |
| `PROJECT_NAME` | Name of your project | Any valid directory name |
| `GITHUB_USERNAME` | Your GitHub handle | — |
| `LICENSE` | License type | `MIT`, `Apache-2.0`, `GPL-3.0`, `BSD-3-Clause`, `None` |
| `SETUP_DOCKER` | Create Docker configuration | `true`, `false` |
| `SETUP_CI` | Set up GitHub Actions | `true`, `false` |

Full option list:

```text
Usage: project-init.sh [OPTIONS]

    --config FILE       Use specific configuration file
    --type TYPE         Set project type
    --name NAME         Set project name
    --dir DIRECTORY     Set project directory
    --non-interactive   Run in non-interactive mode (uses env vars)
    --help              Show help message
```

The wizard logs to `~/.project-wizard/wizard.log`.

### ForkMe

Forking and cloning strategies that go beyond `git clone` — shallow and sparse checkouts for large repos, filetype extraction, and metadata-only analysis:

```bash
# Quick shallow clone for review
./forkme.sh --strategy shallow --depth 1 owner/repo

# Extract documentation only
./forkme.sh --strategy filetype --file-types "md,txt" owner/repo

# Pull just config and source paths for an audit
./forkme.sh --strategy sparse --sparse-paths "src/,*.config" owner/repo

# Repository metadata without cloning
./forkme.sh --analyze-only owner/repo
```

→ [Full ForkMe documentation](FORKME/FORKME.md) · [Quick reference](FORKME/FORKME-QUICK-REFERENCE.md)

### StashMe

Saves uncommitted changes across every git repo under a directory tree to timestamped remote backup branches (`stashme/2026-02-03-143021`). It never modifies your working branch:

```bash
./stashme.sh                                    # stash all repos in ~/github
./STASHME/stashme.sh ~/projects                 # a specific tree
./stashme.sh --list                             # repos with uncommitted changes
./stashme.sh --dry-run                          # preview
./stashme.sh -m "WIP: saving before vacation"   # custom message
./stashme.sh --restore                          # recover stashed changes
./stashme.sh --cleanup                          # remove old stashme branches
```

→ [Full StashMe documentation](STASHME/STASHME.md) · [Quick reference](STASHME/STASHME-QUICK-REFERENCE.md)

### Git Init

Creates a git repo (and optionally the GitHub remote) in interactive or headless mode, preferring `gh` and falling back to `npx degit` for templates:

```bash
./git_init.sh                                                   # interactive
./git_init.sh --headless -n myrepo -u myuser --gitignore python,macos --scaffold python
./git_init.sh --headless -n myrepo -u myuser -t octocat/template-repo
./git_init.sh --headless -n localrepo --no-push
./git_init.sh --headless -n previewme --dry-run                 # preview only
```

### Rename Directory

Renames a directory with pre-flight validation — checks source/target paths and permissions, detects and offers to stop related Docker containers, verifies git status, optionally backs up first, then verifies the result:

```bash
./rename-directory.sh ~/projects/old-name ~/projects/new-name
./rename-directory.sh --help
```

→ [Quick reference](RENAME-DIRECTORY-QUICK-REFERENCE.md)

### Create Package

```bash
./create_package.sh awesome-lib   # → ~/github/awesome-lib, seeded from microsoft/python-package-template
```

## 🔒 Prerequisites

**Required**: Git and Bash 4.0+ (plus Python 3 for `tools/unwrap-prose.py`).

**Optional, depending on the tool**: GitHub CLI (`gh`) for repository creation and forking, `curl` for gitignore.io lookups, `rsync` for `create_package.sh`, Docker for `rename-directory.sh` container handling, and the language toolchains (Python 3.8+, Node 16+, Rust/Cargo, Go 1.21+) matching whatever `project-init.sh` scaffolds.

## ✅ Development

There is no test suite. The gates are ShellCheck and the markdown one-paragraph-per-line rule:

```bash
# Lint (.shellcheckrc applies: SC2034/SC2086/SC1091 disabled)
shellcheck --severity=warning *.sh FORKME/forkme.sh STASHME/stashme.sh

# Markdown gate — one paragraph per line
python3 tools/unwrap-prose.py --check     # fix with: --write
```

CI is [`.github/workflows/ci.yml`](.github/workflows/ci.yml), a thin caller of the hub's shared `bamr87/bamr87/.github/workflows/standard-ci.yml` gate — don't edit gate logic here. [`.github/workflows/claude.yml`](.github/workflows/claude.yml) is the hub-seeded `@claude` mention handler, and [`.github/workflows/markdown-oneline.yml`](.github/workflows/markdown-oneline.yml) is the prose gate.

New scripts follow the existing conventions: `set -euo pipefail`, a structured header comment (File/Description/Author/Version), colour-aware logging helpers, and a row in the tool index above.

Commits use [Conventional Commits](https://www.conventionalcommits.org/) (`type(scope): description`). Branch from the default branch and open a PR; never push to it directly.

## 🧭 Fleet context

This repo is one of ~40 managed by the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87). Shared CI, release, schema, agent-context, and lint/editor configuration are **seeded from the hub** (`templates/` via `tools/fanout.sh`) rather than maintained here — `.editorconfig`, `.github/workflows/ci.yml`, `.github/workflows/claude.yml`, `.github/workflows/markdown-oneline.yml`, and `tools/unwrap-prose.py` all arrived that way. Prefer adopting a hub kit over hand-rolling an equivalent.

Because it is vendored as a submodule, changes are committed and pushed **here** first; the hub only bumps its pointer afterwards.

## 📄 License

MIT — see [LICENSE](LICENSE).

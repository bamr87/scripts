# 🛠️ scripts

> Standalone Bash utilities for project scaffolding, GitHub repository management and multi-repo maintenance.

[![CI](https://github.com/bamr87/scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/bamr87/scripts/actions/workflows/ci.yml) [![License](https://img.shields.io/github/license/bamr87/scripts)](LICENSE)

## Overview

A standalone collection of Bash command-line utilities (plus one Python tool) for project bootstrapping, GitHub repository management, and multi-repo maintenance.

There is no application to build and no dependency install — every script is self-contained and runs directly. This repo is also vendored as a submodule of the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87), which installs several of these scripts as named CLI commands (see [Installation](#-installation)).

## 📦 Features

Every tool, the command the hub installs it as, and what it does:

| Script | Command | What it does |
| --- | --- | --- |
| [`project-init.sh`](project-init.sh) | `project-wizard` | Interactive/non-interactive project scaffolding wizard — Django, React, Node, Python, custom; optional Docker, CI, license, and GitHub repo creation |
| [`forkme.sh`](FORKME/forkme.sh) → `FORKME/forkme.sh` | `forkme` | Repository forking/cloning utility with 10 strategies (full, shallow, sparse, toplevel, structure, filetype, analysis, mirror, bundle, metadata-only) |
| [`STASHME/stashme.sh`](STASHME/stashme.sh) | `stashme` | Multi-repo cloud stash — pushes uncommitted work across many repos to timestamped `stashme/…` backup branches, with restore and cleanup modes |
| [`git_init.sh`](git_init.sh) | `git-init` | Interactive/headless git + GitHub repo creator; prefers `gh`, falls back to `npx degit` for templates, uses gitignore.io for `.gitignore` |
| [`rename-directory.sh`](rename-directory.sh) | `rename-dir` | Safe directory rename with git/Docker pre-flight checks and optional backup |
| [`create_package.sh`](create_package.sh) | `create-package` | Bootstraps a Python package repo from `microsoft/python-package-template` |
| [`tools/unwrap-prose.py`](tools/unwrap-prose.py) | — | Liquid-safe markdown unwrapper enforcing one-paragraph-per-line; backs the `markdown-oneline` CI gate |

Per-tool guides live next to the tools: [`FORKME/`](FORKME/FORKME.md), [`STASHME/`](STASHME/STASHME.md), and [`docs/rename-directory-quick-reference.md`](docs/rename-directory-quick-reference.md).

## Quick start

```bash
git clone https://github.com/bamr87/scripts.git
cd scripts
```

Then, from the checkout:

```bash
# install: none; every tool runs from the checkout (./install.sh only puts project-wizard on PATH, see Installation)
./project-init.sh --help                                          # every tool prints its own flags with --help
./git_init.sh --headless -n previewme --dry-run                   # smoke test, no side effects (there is no test suite)
./STASHME/stashme.sh --dry-run                                    # smoke test, no side effects
shellcheck --severity=warning *.sh FORKME/forkme.sh STASHME/stashme.sh   # lint (.shellcheckrc disables SC2034/SC2086/SC1091)
python3 tools/unwrap-prose.py --check                             # markdown one-paragraph-per-line (fix with --write)
python3 tools/docs_index.py --check                               # docs/README.md index is current (rebuild with --write)
```

## 🚀 Installation

There are two ways to get these tools on your `PATH`, and which one you want depends on whether you also use the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87).

**If you have the dash checked out**, use its bootstrap — do *not* run `install.sh`. `tools/setup.sh` in the hub marks every `*.sh` here executable and symlinks the full set into `~/.local/bin` as `forkme`, `stashme`, `git-init`, `project-wizard`, `rename-dir`, and `create-package`:

```bash
cd /path/to/bamr87        # the hub checkout
./tools/setup.sh          # or: ./tools/setup-dev.sh
```

**If you only have this repo**, use the standalone installer. It is narrower on purpose — it wires up the Project Initialization Wizard only (`project-wizard`), creates `~/.project-wizard/`, appends `~/.local/bin` to your shell `PATH`, and drops a copy of `.env.example` for you to customize:

```bash
git clone https://github.com/bamr87/scripts.git
cd scripts
./install.sh
source ~/.zshrc          # or ~/.bashrc
```

Running both is harmless (the symlinks are idempotent), but redundant — the hub's setup is a strict superset for CLI installation.

Every script also runs directly with no installation at all; each prints its options with `--help`.

## 🎯 Usage

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

To set your own defaults, copy [`.env.example`](.env.example) and either pass it with `--config FILE` (any mode; it is applied where it appears, so put it first and let later flags override it) or save it as `.env` in the directory you run the wizard from (interactive mode only; a `.env` overrides flags and `--config`). Only the variables below are read; the rest of `.env.example` is reserved and currently ignored. An unsupported `PROJECT_TYPE` stops the wizard before anything is created. Key options:

| Variable | Description | Options |
| --- | --- | --- |
| `PROJECT_TYPE` | Type of project to create | `django`, `react`, `node`, `python`, `custom` |
| `PROJECT_NAME` | Name of your project | Any valid directory name |
| `PROJECT_DIR` | Where to create it | Defaults to `~/github/$PROJECT_NAME` |
| `PROJECT_DESCRIPTION` | Used in the README and GitHub repo | — |
| `GITHUB_USERNAME` / `GITHUB_EMAIL` | Your GitHub handle and email | Default to `git config user.name` / `user.email` |
| `LICENSE` | License type | `MIT`, `Apache-2.0`, `GPL-3.0`, `None` |
| `PRIVATE_REPO` | Create the GitHub repo as private | `true`, `false` |
| `SETUP_DOCKER` | Create Docker configuration | `true`, `false` |
| `SETUP_CI` | Set up GitHub Actions | `true`, `false` |

`./project-init.sh --help` prints the full option list. The wizard logs to `~/.project-wizard/wizard.log`.

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
./STASHME/stashme.sh                                    # stash all repos in ~/github
./STASHME/stashme.sh ~/projects                         # a specific tree
./STASHME/stashme.sh --list                             # repos with uncommitted changes
./STASHME/stashme.sh --dry-run                          # preview
./STASHME/stashme.sh -m "WIP: saving before vacation"   # custom message
./STASHME/stashme.sh --restore                          # recover stashed changes
./STASHME/stashme.sh --cleanup                          # remove old stashme branches
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

→ [Quick reference](docs/rename-directory-quick-reference.md)

### Create Package

```bash
./create_package.sh awesome-lib   # → ~/github/awesome-lib, seeded from microsoft/python-package-template
./create_package.sh --help
```

The name must be a plain directory name; anything starting with `-` or containing `/` is rejected. The template files are staged (`git add .`) but not committed.

## 🔒 Prerequisites

**Required**: Git and Bash 4.0+ (plus Python 3 for the maintenance scripts in `tools/`).

**Optional, depending on the tool**: GitHub CLI (`gh`) for repository creation and forking, `curl` for gitignore.io lookups, `rsync` for `create_package.sh`, Docker for `rename-directory.sh` container handling, and the language toolchains (Python 3.8+ for `django`/`python`, Node 16+ with `npm`/`npx` for `react`/`node`) matching whatever `project-init.sh` scaffolds.

## Documentation

The [docs index](docs/README.md) lists every document with a one-line summary: the [ForkMe guide](FORKME/FORKME.md), the [StashMe guide](STASHME/STASHME.md), the [rename-directory quick reference](docs/rename-directory-quick-reference.md), the [decision log](docs/adr/README.md) and the [PRD](PRD.md).

## Project structure

| Path | What |
| --- | --- |
| `*.sh` (root) | The tools themselves (`forkme.sh` is a symlink to `FORKME/forkme.sh`); see [Features](#-features) |
| `FORKME/`, `STASHME/` | ForkMe and StashMe, each with its own guide, quick reference and examples |
| `docs/` | Docs index, decision log, the rename-directory quick reference |
| `tools/` | Repo maintenance scripts (the prose gate and the docs index generator) |
| `features/`, `verify/` | Feature index and verification scenarios |

## ✅ Development

There is no test suite: the gates are ShellCheck, the markdown one-paragraph-per-line rule and the docs index check, all in the [Quick start](#quick-start) block. In CI, [`markdown-oneline.yml`](.github/workflows/markdown-oneline.yml) enforces the prose rule and [`ci.yml`](.github/workflows/ci.yml) calls the hub's shared `standard-ci.yml`; ShellCheck runs locally. [`claude.yml`](.github/workflows/claude.yml) is the `@claude` handler. Conventions for new scripts, commits and branches live in [AGENTS.md](AGENTS.md).

## Contributing

Contributions are welcome via pull request. Use [Conventional Commits](https://www.conventionalcommits.org/) and keep the CI checks green. The fleet-wide workflow is described in the hub's [CONTRIBUTING.md](https://github.com/bamr87/bamr87/blob/main/CONTRIBUTING.md). AI agents start with [AGENTS.md](AGENTS.md); [CLAUDE.md](CLAUDE.md) imports it for Claude Code. This repo is a submodule of the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87), so changes land here first.

## Changelog

Notable changes are recorded in [CHANGELOG.md](CHANGELOG.md); the full record is in the [commit history](https://github.com/bamr87/scripts/commits/main).

## 📄 License

MIT — see [LICENSE](LICENSE).

---

<!-- bamr87-portfolio-footer -->
Part of the [bamr87 portfolio](https://github.com/bamr87) — browse every project on [Amr's GitHub profile](https://github.com/bamr87).

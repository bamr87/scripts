# 🛠️ scripts

> scripts' direction is to become the ultimate open home for all things project and repository automation: data, tools, resources and transparency, with standalone Bash utilities for scaffolding, GitHub management and multi-repo maintenance, for everyone ([constitution](docs/constitution.md) §1).

[![CI](https://github.com/bamr87/scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/bamr87/scripts/actions/workflows/ci.yml) [![License](https://img.shields.io/github/license/bamr87/scripts)](LICENSE)

## Overview

A standalone collection of Bash command-line utilities (plus one Python tool) for project bootstrapping, GitHub repository management, and multi-repo maintenance.

There is no application to build and no dependency install — every script is self-contained and runs directly. This repo is also vendored as a submodule of the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87), which installs several of these scripts as named CLI commands (see [Installation](#-installation)).

## 📦 Features

Every tool, the command the hub installs it as, and what it does:

| Script | Command | What it does |
| --- | --- | --- |
| [`project-init.sh`](project-init.sh) | `project-wizard` | Interactive/non-interactive project scaffolding wizard — Django, React, Node, Python, custom; optional Docker, CI, license, and GitHub repo creation; `--dry-run` prints the plan |
| [`forkme.sh`](FORKME/forkme.sh) → `FORKME/forkme.sh` | `forkme` | Repository forking/cloning utility with 10 strategies (full, shallow, sparse, toplevel, structure, filetype, analysis, mirror, bundle, metadata-only) |
| [`STASHME/stashme.sh`](STASHME/stashme.sh) | `stashme` | Multi-repo cloud stash — pushes uncommitted work across many repos to timestamped `stashme/…` backup branches, with restore and cleanup modes |
| [`git_init.sh`](git_init.sh) | `git-init` | Interactive/headless git + GitHub repo creator; prefers `gh`, falls back to `npx degit` for templates, uses gitignore.io for `.gitignore` |
| [`rename-directory.sh`](rename-directory.sh) | `rename-dir` | Safe directory rename with git/Docker pre-flight checks and optional backup; `--dry-run` previews, `--yes` (with `--backup` / `--no-backup`) runs unattended |
| [`create_package.sh`](create_package.sh) | `create-package` | Bootstraps a Python package repo from `microsoft/python-package-template`; `--dry-run` previews, and a non-empty target needs `--force` |
| [`tools/unwrap-prose.py`](tools/unwrap-prose.py) | — | Liquid-safe markdown unwrapper enforcing one-paragraph-per-line; backs the `markdown-oneline` CI gate |

Per-tool guides live next to the tools: [`FORKME/`](FORKME/FORKME.md), [`STASHME/`](STASHME/STASHME.md), and [`docs/rename-directory-quick-reference.md`](docs/rename-directory-quick-reference.md).

## Quick start

```bash
git clone https://github.com/bamr87/scripts.git
cd scripts
```

Then, from the checkout:

```bash
# install: none; every tool runs from the checkout (./install.sh only puts project-wizard on PATH, --uninstall reverses it; see Installation)
./project-init.sh --help                                          # every tool prints its own flags with --help
tests/smoke.sh                                                    # offline safety smoke (sandboxed HOME, stub gh and git, the --dry-run contracts); CI: smoke.yml
./git_init.sh --headless -n previewme --dry-run                   # preview, no side effects (tests/smoke.sh holds this contract)
./STASHME/stashme.sh --dry-run                                    # preview, no side effects (tests/smoke.sh holds this contract)
shellcheck --severity=warning *.sh FORKME/forkme.sh STASHME/stashme.sh tests/*.sh completions/*.bash   # lint (.shellcheckrc disables SC2034/SC2086/SC1091)
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
./install.sh --dry-run   # optional: print every write and change nothing
./install.sh
source ~/.zshrc          # or ~/.bashrc
```

The rc file is picked from your login shell (`$SHELL`) and gets its `PATH` line only once; `--no-shell-rc` leaves your rc files alone. `./install.sh --help` lists every flag.

Don't run both. The hub's setup is a strict superset for CLI installation, so if `~/.local/bin/project-wizard` already exists and is not this checkout's link (the hub's, say), `install.sh` stops before writing anything and prints where the existing one points; pass `--force` only if you want `project-wizard` to point at this checkout instead.

To undo the standalone install, run `./install.sh --uninstall` (add `--dry-run` to preview it). It removes `~/.local/bin/project-wizard` only when it points to this checkout, takes the `PATH` block out of `~/.zshrc` and `~/.bashrc` after copying each to `<rc>.bak`, and asks before deleting `~/.project-wizard/`, which holds your templates and config; with no terminal to ask it keeps the directory, and `--purge` deletes it without asking. A second run changes nothing.

Every script also runs directly with no installation at all; each prints its options with `--help`.

### Shell completions

Tab completion for `forkme`, `stashme` and `git-init` lives in [`completions/`](completions/). It completes every flag, the values of `forkme --strategy` and `--tag-mode` and of `git-init --license` and `--scaffold`, and directories wherever a tool takes one (`stashme`'s base directory and `-d`, `forkme --target` and `--work-dir`, `git-init --path`). Each file also completes the script under its own name, so `./forkme.sh`, `./STASHME/stashme.sh` and `./git_init.sh` work from a checkout. Neither `install.sh` nor the hub's `tools/setup.sh` loads them yet, so add one line to your shell's rc file:

```bash
# ~/.bashrc (bash 3.2 or later)
for f in /path/to/scripts/completions/*.bash; do source "$f"; done

# ~/.zshrc, after compinit if your setup runs it (_toolbelt loads the bash files through bashcompinit)
source /path/to/scripts/completions/_toolbelt
```

[`tests/smoke.sh`](tests/smoke.sh) fails when a completion file stops offering exactly the long flags its tool's `--help` lists, so a new flag goes into both.

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

To set your own defaults, copy [`.env.example`](.env.example) and either pass it with `--config FILE` (any mode; it is applied where it appears, so put it first and let later flags override it) or save it as `.env` in the directory you run the wizard from (interactive mode only; a `.env` overrides flags and `--config`). Only the variables below are read; the rest of `.env.example` is reserved and currently ignored. Both files are parsed as `KEY=VALUE` lines (optional `export `, `#` comments, matching quotes, a leading `~/` for `$HOME`), never sourced: `$(...)`, backticks and `$VAR` stay literal, so running the wizard inside an untrusted checkout cannot execute its `.env`. Prompt answers are stored verbatim too, apostrophes included. An unsupported `PROJECT_TYPE` stops the wizard before anything is created. Key options:

| Variable | Description | Options |
| --- | --- | --- |
| `PROJECT_TYPE` | Type of project to create | `django`, `react`, `node`, `python`, `custom` |
| `PROJECT_NAME` | Name of your project | Any valid directory name |
| `PROJECT_DIR` | Where to create it | Defaults to `~/github/$PROJECT_NAME` |
| `PROJECT_DESCRIPTION` | Used in the README and GitHub repo | — |
| `GITHUB_USERNAME` / `GITHUB_EMAIL` | Your GitHub handle and email | Default to `git config user.name` / `user.email` |
| `LICENSE` | License type | `MIT`, `Apache-2.0`, `GPL-3.0`, `None` |
| `PRIVATE_REPO` | Create the GitHub repo as private | `true`, `false` |
| `CREATE_GITHUB_REPO` | Create the GitHub repo with `gh`; anything but `true` keeps the project local-only | `true` (default), `false` |
| `PUSH_TO_GITHUB` | Push the initial commit to GitHub | `true` (default), `false` |
| `SETUP_DOCKER` | Create Docker configuration | `true`, `false` |
| `SETUP_CI` | Set up GitHub Actions | `true`, `false` |

`./project-init.sh --help` prints the full option list without writing anything. A run logs to `~/.project-wizard/wizard.log`.

To preview a run, add `--dry-run`: the wizard resolves the configuration as usual (prompts included), then prints every file it would write and every `git` and `gh` command it would run, the `gh repo create` call among them. It creates nothing, writes no log and never calls `gh`. Only the flag decides it, so a `DRY_RUN=false` in `./.env` or a `--config` file cannot turn a dry run into a real one:

```bash
PROJECT_NAME=sandbox ./project-init.sh --non-interactive --dry-run
```

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

Each `--file-types` entry must be a plain extension (letters and digits, comma-separated); anything else exits non-zero before cloning, because the list builds a `find … -delete` expression.

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

`--max-depth` must be a non-negative integer; anything else exits non-zero before the search runs.

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

`--dry-run` prints each command shell-quoted (`printf %q`), so a name such as `it's-a-test` shows exactly the argument that would be passed.

### Rename Directory

Renames a directory with pre-flight validation — checks source/target paths and permissions, detects and offers to stop related Docker containers, verifies git status, optionally backs up first, then verifies the result:

```bash
./rename-directory.sh ~/projects/old-name ~/projects/new-name
./rename-directory.sh --dry-run ~/projects/old-name ~/projects/new-name             # checks only, nothing changes
./rename-directory.sh --yes ~/projects/old-name ~/projects/new-name                 # unattended, with a backup
./rename-directory.sh --yes --no-backup ~/projects/old-name ~/projects/new-name     # unattended, no backup
./rename-directory.sh --help
```

It asks up to three questions (stop related containers, continue with uncommitted changes, create a backup). `--yes` answers the first two and takes the backup unless `--no-backup` is given; `--backup` or `--no-backup` alone answers only the backup question. With no stdin to answer from (CI, cron) and no such flag, the run stops before changing anything. If piped answers run out partway, it stops before copying or moving anything and names any containers an earlier answer already stopped.

→ [Quick reference](docs/rename-directory-quick-reference.md)

### Create Package

```bash
./create_package.sh awesome-lib             # → ~/github/awesome-lib, seeded from microsoft/python-package-template
./create_package.sh --dry-run awesome-lib   # print the mkdir, git init, clone, rsync and git add steps; change nothing
./create_package.sh --help
```

The name must be a plain directory name; anything starting with `-` or containing `/` is rejected. A `~/github/<name>` that already exists and is not empty is refused, untouched, unless you pass `--force` to overlay the template onto it. The template files are staged (`git add .`) but not committed.

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
| `completions/` | Bash and zsh tab completion for `forkme`, `stashme` and `git-init`; see [Shell completions](#shell-completions) |
| `docs/` | Docs index, decision log, the rename-directory quick reference |
| `tests/` | `smoke.sh`, the offline safety smoke run by `smoke.yml` |
| `tools/` | Repo maintenance scripts (the prose gate and the docs index generator) |
| `features/`, `verify/` | Feature index and verification scenarios |
| `public/` | The fleet page-feedback widget (vendored) |
| `.github/` | Workflows (hub-kit callers) and `sdlc.yml`, this repo's SDLC profile |

## ✅ Development

The gates are ShellCheck, the offline smoke test [`tests/smoke.sh`](tests/smoke.sh) (side-effect-free `--help` for every tool, `CREATE_GITHUB_REPO` / `PUSH_TO_GITHUB` honored, `install.sh`'s `--dry-run`, `--force` and `--uninstall` contracts, and the `--dry-run` of `git_init.sh`, `forkme.sh`, `stashme.sh`, `project-init.sh`, `rename-directory.sh` and `create_package.sh` writing nothing and making no `gh` call, `git` push, pull, fetch or clone, or `docker stop` (`project-init.sh`'s even when a sourced `./.env` or `--config` sets `DRY_RUN=false`), while a real stash into local bare remotes still reaches its summary, `rename-directory.sh --yes` renames with no stdin, `rename-directory.sh` names the containers it already stopped when piped answers run out, and `create_package.sh` refuses a non-empty target without `--force`; run against a sandboxed `HOME` with recording `gh`, `git` and `docker` stubs), the markdown one-paragraph-per-line rule and the docs index check, all in the [Quick start](#quick-start) block. In CI, [`smoke.yml`](.github/workflows/smoke.yml) runs ShellCheck and the smoke test (the hub's shared `standard-ci.yml` shellchecks nothing here), [`markdown-oneline.yml`](.github/workflows/markdown-oneline.yml) enforces the prose rule and [`ci.yml`](.github/workflows/ci.yml) calls the hub's shared `standard-ci.yml`. [`claude.yml`](.github/workflows/claude.yml) is the `@claude` handler, and `conformance.yml`, `release.yml` (release-please) and `verify.yml` are likewise thin callers of hub workflows. Conventions for new scripts, commits and branches live in [AGENTS.md](AGENTS.md).

## Contributing

Contributions are welcome via pull request. Use [Conventional Commits](https://www.conventionalcommits.org/) and keep the CI checks green. The fleet-wide workflow is described in the hub's [CONTRIBUTING.md](https://github.com/bamr87/bamr87/blob/main/CONTRIBUTING.md). AI agents start with [AGENTS.md](AGENTS.md); [CLAUDE.md](CLAUDE.md) imports it for Claude Code. This repo is a submodule of the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87), so changes land here first.

## Changelog

Notable changes are recorded in [CHANGELOG.md](CHANGELOG.md); the full record is in the [commit history](https://github.com/bamr87/scripts/commits/main).

## 📄 License

MIT — see [LICENSE](LICENSE).

---

<!-- bamr87-portfolio-footer -->
Part of the [bamr87 portfolio](https://github.com/bamr87) — browse every project on [Amr's GitHub profile](https://github.com/bamr87).

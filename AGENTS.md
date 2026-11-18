<!-- kit: sdlc v0.1.0 · AGENTS.md is the CANONICAL agent instructions file (decision D4, UPS-AGENT-07/08). -->

# scripts

> scripts' direction is to become the ultimate open home for all things project and repository automation: data, tools, resources and transparency, with standalone Bash utilities for scaffolding, GitHub management and multi-repo maintenance, for everyone ([constitution](docs/constitution.md) §1).

## What this repo is

A collection of self-contained command-line tools, run straight from a checkout or installed as named commands by the hub's bootstrap. There is no application to build or deploy and no dependency install. A change is done when the script runs cleanly, passes shellcheck, and its docs (the README tool index under Features, plus the tool's own `FORKME/` or `STASHME/` pages) match its actual flags and behavior. Each script's `--help` is the authoritative flag list; docs link to it rather than copying it.

## Stack & commands

Pure Bash 4+ plus one Python 3 script; nothing to install or build.

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

## Layout

| Path | What |
| --- | --- |
| `project-init.sh` | Project scaffolding wizard (Django, React, Node, Python, custom; optional Docker, CI, license, GitHub repo; `--dry-run`); configured by `.env` / `--config` from `.env.example` |
| `install.sh` | Standalone installer: puts `project-wizard` on `PATH` and creates `~/.project-wizard/`; `--dry-run` previews it, `--uninstall` reverses it, and it never replaces a `project-wizard` that is not its own without `--force` |
| `git_init.sh` | Interactive/headless git + GitHub repo creator (prefers `gh`, falls back to `npx degit`; gitignore.io; `--dry-run`) |
| `forkme.sh` → `FORKME/forkme.sh` | Forking/cloning utility with 10 strategies; docs in `FORKME/` |
| `STASHME/stashme.sh` | Multi-repo cloud stash to timestamped `stashme/…` branches, with `--dry-run`, `--restore`, `--cleanup`; docs in `STASHME/` |
| `rename-directory.sh` | Safe directory rename with git/Docker pre-flight checks and optional backup; `--dry-run`, unattended `--yes` / `--backup` / `--no-backup` ([quick reference](docs/rename-directory-quick-reference.md)) |
| `create_package.sh` | Bootstraps a Python package repo from `microsoft/python-package-template`; `--dry-run`, and `--force` to overlay a non-empty target |
| `tests/` | `smoke.sh`: the offline safety contract (side-effect-free `--help`, `CREATE_GITHUB_REPO` / `PUSH_TO_GITHUB` and `git_init.sh --no-push` honored, `install.sh`'s `--dry-run`, `--force` and `--uninstall` contracts, input treated as data and never `eval`ed or sourced, the `--dry-run` of every tool that has one writing nothing and making no `gh`, `git` network or `docker stop` call, `project-init.sh`'s even when a sourced `.env` or `--config` sets `DRY_RUN=false`, a real stash reaching its summary, `rename-directory.sh --yes` with no stdin and its report of containers already stopped when piped answers run out, `create_package.sh` refusing a non-empty target without `--force`), run by `smoke.yml` |
| `tools/` | `unwrap-prose.py` (vendored prose gate) and `docs_index.py` (vendored docs index generator) |
| `completions/` | Hand-written bash completion for `forkme`, `stashme` and `git-init` (`*.bash`, sourced, no shebang) and the zsh loader `_toolbelt` (bashcompinit); `tests/smoke.sh` fails when a file's long flags stop matching its tool's `--help`, so a flag change updates both |
| `docs/` | Docs index, ADRs (`docs/adr/`), guides |
| `features/`, `verify/` | Feature index and the verify kit's scenarios (hub kit) |
| `public/` | The fleet page-feedback widget (vendored) |
| `.claude/` | The `verify-feature` skill and `verifier` agent (hub verify kit) |

`.shellcheckrc`, `.markdownlint.json` and `.editorconfig` hold the lint config; `.editorconfig` is a hub fan-out artifact, byte-identical to the hub's, so never hand-edit it.

## Conventions

- **Backlog of record:** GitHub Issues with the fleet labels (`.github/sdlc.yml`, `backlog.mode: issues`). Pick up issues labelled `agent:ready`; never touch `agent:hold` or `human-review`.
- **Definition of Done:** the fleet default pull request checklist (this repo has no `.github/pull_request_template.md`), plus shellcheck clean and docs matching the script's flags.
- **Decisions:** ADRs in `docs/adr/NNNN-slug.md`, indexed in `docs/adr/README.md`.
- **Commits:** Conventional Commits, `type(scope): description` (`feat fix docs refactor test chore ci`). The PR title is the squash subject.
- **Branches:** `feature/`, `fix/`, `docs/`, `refactor/` or `test/` off `main` (the default branch); open a PR, never push to `main`.
- **Changelog:** `CHANGELOG.md` is written by release-please (`release.yml`, `release-please-config.json`, `.release-please-manifest.json`); never edit it by hand.
- **README-First, README-Last:** read the nearest `README.md` before changing a directory and update it after. The root `README.md` carries the tool index (its Features table), so adding or renaming a script updates it in the same change.
- **New scripts** use `set -euo pipefail`, a structured header comment (File/Description/Author/Version), colour-aware logging helpers, and get a row in the README tool index.
- **Never:** suppress type errors (`as any`, `@ts-ignore`, `# type: ignore`), leave empty exception handlers, or hand-edit the vendored files (`tools/unwrap-prose.py`, `tools/docs_index.py`, `public/fleet-feedback*.js`).

## Retired tooling: don't re-add it

`.github.sh` (a `.github/` structure generator) and `linting/` (`setup-lint-configs.sh`, `validate-lint-setup.sh`) were retired in favour of the hub's `tools/fanout.sh` kits: `--kit standardize` owns `.editorconfig`, `ci.yml` and agent context; `--kit prose` owns the markdown gate; `templates/release-pipeline/` owns release automation; `--kit deps-latest` owns the always-latest dependency policy, which is why the community kit's `.github/dependabot.yml` covers `github-actions` only: never add a package ecosystem to it. Config distribution is registry-driven, additive-only and PR-based from the hub, never a local script walking hardcoded paths.

## Fleet context

Member of the bamr87 fleet, vendored as the `projects/scripts` submodule of the hub [bamr87/bamr87](https://github.com/bamr87/bamr87); the standards live in its [specs/](https://github.com/bamr87/bamr87/tree/main/specs) (the Universal Project Standard). Commit and push here first; the hub bumps its pointer afterwards.

- Shared CI (`ci.yml` → the hub's `standard-ci.yml`), the `@claude` handler (`claude.yml`), the prose gate (`markdown-oneline.yml`), conformance and verify callers, `.editorconfig` and `tools/unwrap-prose.py` are seeded from the hub's `templates/`; don't edit their logic here. Prefer adopting a hub kit over hand-rolling an equivalent.
- The hub's bootstrap (`tools/setup.sh`) marks every `*.sh` here executable and symlinks the tools into `~/.local/bin` as `forkme`, `stashme`, `git-init`, `project-wizard`, `rename-dir` and `create-package`; `tools/devtools-env.sh` exports this checkout as `BAMR87_SCRIPTS`.
- Neither the hub's `tools/run-all-tests.sh` nor the shared `standard-ci.yml` shellchecks this repo; this repo's own `smoke.yml` does, and runs `tests/smoke.sh`. Keep every script clean, and never run a tool against your real `HOME` to test it: `install.sh` installs and `project-init.sh` can create a public repo.
- The registry opts this repo into the weekly repo-evolution loop (`auto_evolve: true`), which opens draft improvement PRs here; the fleet-pulse doctor and the issue pipeline also open PRs, and none of them merges.

## Standard deviations

none

## Governance

Read [`docs/constitution.md`](docs/constitution.md) before changing anything: it is the highest-precedence rule set here and wins over this file when they disagree. It changes only through a numbered record in [`docs/amendments/`](docs/amendments/), ratified by the maintainer merging the PR; agents propose, never merge. Every user-facing feature has a stable id in [`features/features.yml`](features/features.yml) with `status`, location and the PRD requirement ids it serves; the PRD's "Feature catalog" block is generated from it (`python3 <bamr87/bamr87>/tools/governance_lint.py prd-sync . --write`; check with `… check .`). Never hand-edit that block or `CHANGELOG.md`.

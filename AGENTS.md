<!-- kit: sdlc v0.1.0 · AGENTS.md is the CANONICAL agent instructions file (decision D4, UPS-AGENT-07/08). -->

# scripts

> Standalone Bash utilities (plus one Python tool) for project scaffolding, GitHub repository management and multi-repo maintenance.

## What this repo is

A collection of self-contained command-line tools, run straight from a checkout or installed as named commands by the hub's bootstrap. There is no application to build or deploy and no dependency install. A change is done when the script runs cleanly, passes shellcheck, and its docs (the README tool index under Features, plus the tool's own `FORKME/` or `STASHME/` pages) match its actual flags and behavior. Each script's `--help` is the authoritative flag list; docs link to it rather than copying it.

## Stack & commands

Pure Bash 4+ plus one Python 3 script; nothing to install or build.

```bash
# install: none; every tool runs from the checkout (./install.sh only puts project-wizard on PATH, see Installation)
./project-init.sh --help                                          # every tool prints its own flags with --help
./git_init.sh --headless -n previewme --dry-run                   # smoke test, no side effects (there is no test suite)
./STASHME/stashme.sh --dry-run                                    # smoke test, no side effects
shellcheck --severity=warning *.sh FORKME/forkme.sh STASHME/stashme.sh   # lint (.shellcheckrc disables SC2034/SC2086/SC1091)
python3 tools/unwrap-prose.py --check                             # markdown one-paragraph-per-line (fix with --write)
python3 tools/docs_index.py --check                               # docs/README.md index is current (rebuild with --write)
```

## Layout

| Path | What |
| --- | --- |
| `project-init.sh` | Project scaffolding wizard (Django, React, Node, Python, custom; optional Docker, CI, license, GitHub repo); configured by `.env` / `--config` from `.env.example` |
| `install.sh` | Standalone installer: puts `project-wizard` on `PATH` and creates `~/.project-wizard/` |
| `git_init.sh` | Interactive/headless git + GitHub repo creator (prefers `gh`, falls back to `npx degit`; gitignore.io; `--dry-run`) |
| `forkme.sh` → `FORKME/forkme.sh` | Forking/cloning utility with 10 strategies; docs in `FORKME/` |
| `STASHME/stashme.sh` | Multi-repo cloud stash to timestamped `stashme/…` branches, with `--dry-run`, `--restore`, `--cleanup`; docs in `STASHME/` |
| `rename-directory.sh` | Safe directory rename with git/Docker pre-flight checks and optional backup ([quick reference](docs/rename-directory-quick-reference.md)) |
| `create_package.sh` | Bootstraps a Python package repo from `microsoft/python-package-template` |
| `tools/` | `unwrap-prose.py` (vendored prose gate) and `docs_index.py` (vendored docs index generator) |
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
- **Changelog:** `CHANGELOG.md` is written by release-please (`release.yml`, `release-please-config.json`); never edit it by hand.
- **README-First, README-Last:** read the nearest `README.md` before changing a directory and update it after. The root `README.md` carries the tool index (its Features table), so adding or renaming a script updates it in the same change.
- **New scripts** use `set -euo pipefail`, a structured header comment (File/Description/Author/Version), colour-aware logging helpers, and get a row in the README tool index.
- **Never:** suppress type errors (`as any`, `@ts-ignore`, `# type: ignore`), leave empty exception handlers, or hand-edit the vendored files (`tools/unwrap-prose.py`, `tools/docs_index.py`, `public/fleet-feedback*.js`).

## Retired tooling: don't re-add it

`.github.sh` (a `.github/` structure generator) and `linting/` (`setup-lint-configs.sh`, `validate-lint-setup.sh`) were retired in favour of the hub's `tools/fanout.sh` kits: `--kit standardize` owns `.editorconfig`, `ci.yml` and agent context; `--kit prose` owns the markdown gate; `templates/release-pipeline/` owns release automation; `--kit deps-latest` owns the always-latest dependency policy, which is why nothing here should emit a `dependabot.yml`. Config distribution is registry-driven, additive-only and PR-based from the hub, never a local script walking hardcoded paths.

## Fleet context

Member of the bamr87 fleet, vendored as the `projects/scripts` submodule of the hub [bamr87/bamr87](https://github.com/bamr87/bamr87); the standards live in its [specs/](https://github.com/bamr87/bamr87/tree/main/specs) (the Universal Project Standard). Commit and push here first; the hub bumps its pointer afterwards.

- Shared CI (`ci.yml` → the hub's `standard-ci.yml`), the `@claude` handler (`claude.yml`), the prose gate (`markdown-oneline.yml`), conformance and verify callers, `.editorconfig` and `tools/unwrap-prose.py` are seeded from the hub's `templates/`; don't edit their logic here. Prefer adopting a hub kit over hand-rolling an equivalent.
- The hub's bootstrap (`tools/setup.sh`) marks every `*.sh` here executable and symlinks the tools into `~/.local/bin` as `forkme`, `stashme`, `git-init`, `project-wizard`, `rename-dir` and `create-package`; `tools/devtools-env.sh` exports this checkout as `BAMR87_SCRIPTS`.
- Neither the hub's `tools/run-all-tests.sh` nor the shared `standard-ci.yml` shellchecks this repo today, so run shellcheck yourself and keep every script clean.
- The registry opts this repo into the weekly repo-evolution loop (`auto_evolve: true`), which opens draft improvement PRs here; the fleet-pulse doctor and the issue pipeline also open PRs, and none of them merges.

## Standard deviations

none

## Governance

Read [`docs/constitution.md`](docs/constitution.md) before changing anything: it is the highest-precedence rule set here and wins over this file when they disagree. It changes only through a numbered record in [`docs/amendments/`](docs/amendments/), ratified by the maintainer merging the PR; agents propose, never merge. Every user-facing feature has a stable id in [`features/features.yml`](features/features.yml) with `status`, location and the PRD requirement ids it serves; the PRD's "Feature catalog" block is generated from it (`python3 <bamr87/bamr87>/tools/governance_lint.py prd-sync . --write`; check with `… check .`). Never hand-edit that block or `CHANGELOG.md`.

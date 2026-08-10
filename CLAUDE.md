# CLAUDE.md

Guidance for AI coding agents (Claude Code, Copilot, Cursor) working in **scripts**.

A standalone collection of Bash command-line utilities (plus one Python tool) for project bootstrapping, GitHub repository management, and multi-repo maintenance. There is no application to build or deploy — each script is a self-contained tool, so "done" means the script runs cleanly, passes shellcheck, and the docs (`README.md` plus the tool's own `FORKME/`/`STASHME/` pages) match its actual flags and behavior.

## What's here

- `project-init.sh` — interactive/non-interactive project scaffolding wizard (Django, React, Node, Python, Rust, Go, custom; optional Docker, CI, license, GitHub repo creation). Configured via `.env` (copy `env.example`); `install.sh` wires it into a per-user CLI.
- `git_init.sh` — interactive/headless git + GitHub repo creator (prefers `gh`, falls back to `npx degit` for templates; gitignore.io for `.gitignore`; supports `--dry-run`).
- `forkme.sh` (symlink → `FORKME/forkme.sh`) — repository forking/cloning utility with 10 strategies (full, shallow, sparse, filetype, analysis, mirror, …); full docs under `FORKME/`.
- `STASHME/stashme.sh` — multi-repo cloud stash: pushes uncommitted work across many repos to timestamped `stashme/…` backup branches, with `--dry-run`, `--restore`, and `--cleanup`; full docs under `STASHME/`.
- `rename-directory.sh` — safe directory rename with git/Docker pre-flight checks and optional backup (see `RENAME-DIRECTORY-QUICK-REFERENCE.md`).
- `create_package.sh` — bootstraps a Python package repo from `microsoft/python-package-template`.
- `tools/unwrap-prose.py` — Liquid-safe markdown unwrapper enforcing one-paragraph-per-line; seeded from the hub's prose kit and backed by `.github/workflows/markdown-oneline.yml`.
- `.shellcheckrc`, `.markdownlint.json`, `.editorconfig` hold this repo's lint config (`.editorconfig` is a hub fan-out artifact — byte-identical to the hub's; don't hand-edit it).

**Don't re-add fleet-wide config/scaffold tooling here.** `.github.sh` (a `.github/` structure generator) and `linting/` (`setup-lint-configs.sh` / `validate-lint-setup.sh`) were retired in favour of the hub's `tools/fanout.sh` kits: `--kit standardize` owns `.editorconfig` + `ci.yml` + agent context, `--kit prose` owns the markdown gate, `templates/release-pipeline/` owns release automation, and `--kit deps-latest` owns the ALWAYS-LATEST dependency policy (which is why nothing here should emit a `dependabot.yml`). Config distribution is registry-driven, additive-only, and PR-based from the hub — not a local script walking hardcoded paths.

## Stack & commands

Pure Bash 4+ plus one Python 3 script — no dependency install, build step, or dev server. Scripts run directly (`chmod +x` if needed).

```bash
# lint — the repo's primary gate (.shellcheckrc applies: SC2034/SC2086/SC1091 disabled):
shellcheck --severity=warning *.sh FORKME/forkme.sh STASHME/stashme.sh

# markdown gate — one paragraph per line (CI: .github/workflows/markdown-oneline.yml):
python3 tools/unwrap-prose.py --check      # fix with: python3 tools/unwrap-prose.py --write

# smoke-test without side effects (where a script supports it):
./git_init.sh --headless -n previewme --dry-run
./STASHME/stashme.sh --dry-run
```

There is no test suite (no `tests/` directory or test runner). CI is `.github/workflows/ci.yml`, a thin caller of the hub's shared `bamr87/bamr87/.github/workflows/standard-ci.yml` gate — don't edit the gate logic here. `.github/workflows/claude.yml` is the hub-seeded `@claude` mention handler (OAuth-first auth).

New scripts follow the existing conventions: `set -euo pipefail`, a structured header comment (File/Description/Author/Version), color-aware logging helpers, and an entry in `README.md`'s tool index.

## Conventions

- Conventional Commits: `type(scope): description` (`feat`/`fix`/`docs`/`refactor`/`test`/`chore`/`ci`).
- Branches: the hub's `.gitmodules` and registry declare `main` for this repo, but the default branch on GitHub is currently still `master` (rename not yet done) — check `git branch --show-current` / `git remote show origin` rather than assuming. Branch from the default branch and open a PR; never push to it directly.
- README-First, README-Last: read the nearest `README.md` before changing a directory, and update it after — this repo's root `README.md` is the tool index, so adding/renaming a script updates it in the same change.
- Don't suppress type errors (`as any`, `@ts-ignore`, `# type: ignore`) or leave empty exception handlers.

## Fleet context

This repo is one of ~40 managed by the [bamr87/bamr87 dash](https://github.com/bamr87/bamr87) (registry: `_data/projects.yml`; tiered baseline: `docs/STANDARDS.md`). It is vendored there as a git submodule: commit and push changes **here** first — the hub only bumps its pointer afterwards. Shared CI, release, schema, and agent kits are seeded from the hub's `templates/`; prefer adopting those over hand-rolling equivalents.

It is a foundational repo for the hub: the hub's aggregate verification (`tools/run-all-tests.sh`) shellchecks the **top-level `*.sh` here**, so a shellcheck warning in a root-level script fails the hub's checks; the hub's bootstrap (`tools/setup.sh`) marks every `*.sh` here executable and exposes this checkout as `BAMR87_SCRIPTS`. Keep top-level scripts shellcheck-clean.

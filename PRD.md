# PRD — scripts

> The product requirements for bamr87/scripts: the problem, users, goals, features, requirements, success measures and open questions.

Derived from the README, agent docs, config and code in this repo. Anything not stated in those sources is marked **TBD**; success metrics are proposals.

## 1. Overview / problem

A standalone collection of Bash command-line utilities (plus one Python tool) for project bootstrapping, GitHub repository management and multi-repo maintenance. No build and no dependency install; every script is self-contained. It is also vendored as a submodule of the bamr87 dash, which installs the scripts onto `PATH`.

## 2. Target users

- Developers scaffolding new projects or GitHub repos from the terminal
- Maintainers of many repositories (multi-repo stash/backups, forking strategies)
- The bamr87 dash, which installs these tools

## 3. Goals and non-goals

**Goals**

- Self-contained scripts that run directly with `--help` and no install
- Safe defaults (dry-runs, pre-flight checks, backups)
- Non-interactive modes for automation

**Non-goals**

- A packaged application or shared library
- Language-specific build tooling

## 4. Core features (current)

- `project-init.sh` (`project-wizard`): scaffolding for Django, React, Node, Python, custom; optional Docker, CI, license, GitHub repo
- `FORKME/forkme.sh` (`forkme`): 10 fork/clone strategies
- `STASHME/stashme.sh` (`stashme`): multi-repo cloud stash to `stashme/…` branches with restore/cleanup
- `git_init.sh` (`git-init`): git + GitHub repo creator
- `rename-directory.sh` (`rename-dir`): safe rename with git/Docker pre-flight and backup
- `create_package.sh`: Python package bootstrap
- `tools/unwrap-prose.py`: markdown unwrapper backing the `markdown-oneline` CI gate
- `install.sh` standalone installer (project-wizard only)

## 5. Requirements

**Functional**

- Each script supports `--help`
- Wizard supports env-var/flag/`--config` non-interactive mode
- Destructive tools offer dry-run and/or backup

**Non-functional**

- Portable Bash; no external install required beyond standard CLI tools and optionally `gh`
- Idempotent installation

## 6. Success metrics (proposed — not defined in sources)

- Scripts with passing smoke tests
- Issues reporting data loss: target zero
- Adoption: TBD

## 7. Roadmap / open questions

- `features/features.yml` is still a TODO placeholder — feature index TBD
- Supported OS matrix: TBD

## 8. Links

- [README.md](README.md) · [AGENTS.md](AGENTS.md) · [CHANGELOG.md](CHANGELOG.md) · [FORKME/FORKME.md](FORKME/FORKME.md) · [STASHME/STASHME.md](STASHME/STASHME.md) · [Issues](https://github.com/bamr87/scripts/issues) (the backlog of record)

<!-- kit: governance v0.1.0 -->
# 0002 — Missions

- **Status:** proposed
- **Date:** 2026-11-16
- **Proposed by:** Grok Bot (agent), at the maintainer's request
- **Ratified by:**
- **Affects:** constitution §1; PRD.md §1.1; SCRIPTS-011
- **Supersedes:** none
- **Related:** [PRD.md](../../PRD.md) §1.1

## Context

Constitution §1 was a single mission sentence or short paragraph, not one direction statement with exactly three numbered missions. The fleet rule is that every repo's constitution §1 uses that form, adopted through a numbered amendment the maintainer ratifies by merging. Mission 1 is the maintainer's own wording, adapted to this repo: provide data, tools, resources and transparency for all stakeholders, practitioners in the domain, and the general public. The ambition is the direction, not a claim that the work is already finished.

The earlier §1 text was:

> A standalone collection of Bash command-line utilities (plus one Python tool) for project bootstrapping, GitHub repository management and multi-repo maintenance. No build and no dependency install; every script is self-contained. It is also vendored as a submodule of the bamr87 dash, which installs the scripts onto `PATH`.

## Amendment

Retitle constitution §1 **Missions**. Replace the body of §1 with the following. Any invariants or other normative rules that already lived outside §1 are unchanged.

scripts' direction is to become the ultimate open home for all things project and repository automation — data, tools, resources and transparency, gathered in one place that anyone can inspect and reuse.

1. **Provide data, tools, resources and transparency for all stakeholders, maintainers, automation practitioners and the general public.** Maintainers, contributors, automation builders, and the general public are first-class audiences. The aim is a shared, open commons: the same scripts, the same tools, and the same trail of evidence for everyone.
2. **Make project bootstrapping, GitHub repository management and multi-repo maintenance possible with standalone, self-contained tools.** No build and no dependency install; every script can be read, copied and run on its own. The collection is Bash command-line utilities plus one Python tool.
3. **Put those tools on every maintainer's PATH, and make operating a fleet of repos effortless and inspectable.** The collection is also vendored as a submodule of the bamr87 dash, which installs the scripts onto `PATH` — an open toolkit for working with all things project and repository automation.

These missions set the course; they do not claim the work is finished. They serve the existing constitution and PRD purpose: self-contained utilities with no build step, vendored into the dash. The earlier mission paragraph is absorbed into these three. Every feature must trace to them.

_Source: [../PRD.md](../PRD.md) §1.1._

## Consequences

Agents and reviewers judge fit against these three missions before inventing scope, treating them as the direction of the repo rather than a description of what already ships. The same text is added as PRD.md §1.1 so the constitution's `_Source:` line stays accurate. The PRD purpose, goals, feature catalog and invariants outside this addition are unchanged except for a new catalog entry (SCRIPTS-011) and a regenerated feature-catalog block where the repo already has one. This PR also aligns the README and AGENTS.md one-liners with the missions and links them to constitution §1.

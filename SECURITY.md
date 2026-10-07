# Security Policy

## Supported versions

This repository ships no packaged releases — every tool is a self-contained script run straight from a checkout. Only the tip of the default branch is supported; there are no maintained older branches or tags to backport a fix to. Update by pulling the default branch.

## Reporting a vulnerability

Report privately through GitHub's [security advisories](https://github.com/bamr87/scripts/security/advisories/new) rather than opening a public issue. Expect an initial response within seven days.

Please include the script and version you ran, the exact command line, and the shell and OS (`bash --version`, `uname -a`). A minimal reproduction — ideally against a throwaway directory or repository — is worth more than a description.

## What counts as a vulnerability here

These are local developer tools: they run as you, with your credentials, over paths and repositories you name. The interesting failure modes are the ones where a script does something you did not ask for:

- Shell injection through a value the operator does not control — a repository name, branch name, file path, or GitHub API response that reaches `eval`, an unquoted expansion, or a command substitution.
- Destructive action outside the target path — anything that writes, renames, force-pushes, or deletes outside the directory or repository passed on the command line. `--dry-run` performing a real mutation belongs here too.
- Credential leakage — a token, SSH key, or `gh` auth material echoed to stdout, written to a log under `~/.project-wizard/`, or committed into a generated repository.
- Fetching and executing remote content without the operator asking for it.

## Out of scope

- Anything requiring the attacker to already have write access to your machine or your shell profile.
- The scripts' reliance on `git`, `gh`, `curl`, and `npx` — trusting those binaries on `PATH` is the premise of the tools, not a flaw in them.
- Third-party content these scripts fetch on request (gitignore.io templates, `degit` template repositories, GitHub template repos). Report those to their owners.
- Missing hardening that has no reachable exploit, absent a concrete scenario.

## Fleet context

This repository is one of the projects tracked by the [bamr87/bamr87](https://github.com/bamr87/bamr87) hub. A report that affects the shared CI, agent, or prose kits seeded from that hub's `templates/` should be filed there so the fix reaches every repository at once.

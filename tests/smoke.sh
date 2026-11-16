#!/usr/bin/env bash
###############################################################################
# File: tests/smoke.sh
# Description: Offline regression smoke for the toolbelt's safety contract:
#              every --help is side-effect free, install.sh refuses unknown
#              options, writes nothing under --dry-run, never replaces or
#              removes a project-wizard that is not its own and --uninstall
#              reverses it, and project-init.sh honors CREATE_GITHUB_REPO and
#              PUSH_TO_GITHUB. Runs in a throwaway HOME with a recording `gh`
#              stub, so nothing reaches GitHub or the caller's dotfiles.
# Author: Amr Abdel-Motaleb <amr.abdel@gmail.com>
# Created: 2026-10-27
# Version: 1.0.0
#
# Usage:
#   tests/smoke.sh        # exits non-zero on the first broken contract
###############################################################################

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ -t 1 ]; then GREEN='\033[0;32m'; RED='\033[0;31m'; RESET='\033[0m'; else GREEN=''; RED=''; RESET=''; fi
FAILED=0
pass() { echo -e "${GREEN}ok${RESET}   $*"; }
fail() { echo -e "${RED}FAIL${RESET} $*"; FAILED=1; }

# A gh that records every call; `repo view` reports "not found" so the wizard
# takes its create path, and `repo create` succeeds without doing anything.
mkdir -p "$WORK/bin"
cat > "$WORK/bin/gh" <<STUB
#!/usr/bin/env bash
echo "gh \$*" >> "$WORK/gh-calls.log"
[ "\$1 \$2" = "repo view" ] && exit 1
exit 0
STUB
chmod +x "$WORK/bin/gh"

# Run a command in a fresh sandbox HOME; prints nothing, returns its exit code.
sandboxed() {
    local home="$1"; shift
    rm -rf "$home"; mkdir -p "$home"
    : > "$WORK/gh-calls.log"
    HOME="$home" PATH="$WORK/bin:$PATH" GIT_CONFIG_GLOBAL=/dev/null "$@" </dev/null >"$WORK/out.txt" 2>&1
}

# 1. --help exits 0 and writes nothing under HOME, even where USER is unset (containers, cron).
for script in project-init.sh install.sh git_init.sh FORKME/forkme.sh STASHME/stashme.sh rename-directory.sh create_package.sh; do
    rc=0; sandboxed "$WORK/home" env -u USER bash "$REPO/$script" --help || rc=$?
    wrote="$(find "$WORK/home" -mindepth 1 | sed "s#$WORK/home#~#" | tr '\n' ' ')"
    if [ "$rc" -ne 0 ]; then fail "$script --help exited $rc"
    elif [ -n "$wrote" ]; then fail "$script --help wrote: $wrote"
    else pass "$script --help is side-effect free"; fi
done

# 2. install.sh refuses an unknown option without installing.
rc=0; sandboxed "$WORK/home" bash "$REPO/install.sh" --bogus || rc=$?
if [ "$rc" -ne 0 ] && [ -z "$(find "$WORK/home" -mindepth 1)" ]; then pass "install.sh refuses an unknown option"
else fail "install.sh --bogus exited $rc and wrote: $(find "$WORK/home" -mindepth 1 | sed "s#$WORK/home#~#" | tr '\n' ' ')"; fi

# 3. project-init.sh: CREATE_GITHUB_REPO / PUSH_TO_GITHUB decide what reaches gh.
scaffold() {
    local name="$1"; shift
    sandboxed "$WORK/home" env NON_INTERACTIVE=true PROJECT_TYPE=custom PROJECT_NAME="$name" \
        PROJECT_DIR="$WORK/projects/$name" GITHUB_USERNAME=smoke GITHUB_EMAIL=smoke@example.invalid \
        LICENSE=MIT SETUP_DOCKER=false SETUP_CI=false "$@" bash "$REPO/project-init.sh" --non-interactive
}

rc=0; scaffold local-only CREATE_GITHUB_REPO=false || rc=$?
if [ "$rc" -ne 0 ]; then fail "CREATE_GITHUB_REPO=false scaffold exited $rc: $(tail -3 "$WORK/out.txt")"
elif grep -q "repo create" "$WORK/gh-calls.log"; then fail "CREATE_GITHUB_REPO=false still called: $(cat "$WORK/gh-calls.log")"
elif [ ! -d "$WORK/projects/local-only/.git" ]; then fail "CREATE_GITHUB_REPO=false scaffold has no git repo"
else pass "CREATE_GITHUB_REPO=false never calls gh repo create"; fi

rc=0; scaffold no-push CREATE_GITHUB_REPO=true PUSH_TO_GITHUB=false || rc=$?
create_call="$(grep "repo create" "$WORK/gh-calls.log" || true)"
if [ "$rc" -ne 0 ]; then fail "PUSH_TO_GITHUB=false scaffold exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ -z "$create_call" ]; then fail "CREATE_GITHUB_REPO=true did not call gh repo create"
elif [[ "$create_call" == *--push* ]]; then fail "PUSH_TO_GITHUB=false still pushed: $create_call"
else pass "PUSH_TO_GITHUB=false creates without --push"; fi

rc=0; scaffold default-push || rc=$?
create_call="$(grep "repo create" "$WORK/gh-calls.log" || true)"
if [ "$rc" -eq 0 ] && [[ "$create_call" == *--public*--push* ]]; then pass "defaults still create a public repo and push"
else fail "default scaffold (exit $rc) called: ${create_call:-nothing}"; fi

# 4. install.sh: --dry-run writes nothing, a re-run adds no second PATH line, a
#    project-wizard that is not this checkout's link is never replaced without
#    --force or removed by --uninstall, and --uninstall leaves only .bak files.
#    SHELL is pinned so the rc file is always ~/.bashrc, whatever runs the suite.
IHOME="$WORK/ihome"
WIZARD_LINK="$IHOME/.local/bin/project-wizard"
FOREIGN="/nonexistent/elsewhere/project-init.sh"
fresh_home() { rm -rf "$IHOME"; mkdir -p "$IHOME"; }
# Run install.sh in $IHOME without resetting it, with stdin closed (not a TTY).
installer() {
    HOME="$IHOME" SHELL=/bin/bash PATH="$WORK/bin:$PATH" GIT_CONFIG_GLOBAL=/dev/null \
        bash "$REPO/install.sh" "$@" </dev/null >"$WORK/out.txt" 2>&1
}
# Every path under $IHOME with a symlink's target or a file's checksum.
snapshot() {
    (cd "$IHOME" && find . -mindepth 1 | LC_ALL=C sort | while IFS= read -r p; do
        if [ -L "$p" ]; then echo "$p -> $(readlink "$p")"
        elif [ -f "$p" ]; then echo "$p $(cksum < "$p")"
        else echo "$p/"; fi
    done)
}
markers() { grep -cxF '# Project Wizard PATH' "$IHOME/.bashrc" 2>/dev/null || true; }
# Files and links left under $IHOME other than *.bak backups.
leftovers() { find "$IHOME" -mindepth 1 \( -type f -o -type l \) ! -name '*.bak' | sed "s#$IHOME#~#" | tr '\n' ' '; }

fresh_home; rc=0; installer --dry-run || rc=$?
if [ "$rc" -ne 0 ]; then fail "install.sh --dry-run exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ -n "$(find "$IHOME" -mindepth 1)" ]; then fail "install.sh --dry-run wrote: $(snapshot | tr '\n' ' ')"
elif ! grep -q '^DRYRUN: ln -sfn ' "$WORK/out.txt"; then fail "install.sh --dry-run did not print the symlink it would make"
else pass "install.sh --dry-run writes nothing"; fi

fresh_home; rc=0; installer || rc=$?; installer || rc=$?
if [ "$rc" -ne 0 ]; then fail "install.sh (twice) exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ "$(markers)" != 1 ]; then fail "install.sh twice left $(markers) PATH markers in ~/.bashrc"
elif [ "$(readlink "$WIZARD_LINK")" != "$REPO/project-init.sh" ]; then fail "install.sh linked project-wizard to '$(readlink "$WIZARD_LINK" || true)'"
else pass "install.sh twice links project-wizard and appends one PATH line"; fi

fresh_home; mkdir -p "$IHOME/.local/bin"; ln -s "$FOREIGN" "$WIZARD_LINK"
rc=0; installer || rc=$?
if [ "$rc" -eq 0 ]; then fail "install.sh replaced a foreign project-wizard link without --force"
elif [ "$(readlink "$WIZARD_LINK")" != "$FOREIGN" ]; then fail "install.sh changed a foreign project-wizard link to '$(readlink "$WIZARD_LINK" || true)'"
elif [ "$(snapshot | wc -l | tr -d ' ')" != 3 ]; then fail "install.sh refused but still wrote: $(snapshot | tr '\n' ' ')"
elif ! grep -qF "$FOREIGN" "$WORK/out.txt"; then fail "install.sh refused without naming the link's current target"
else pass "install.sh refuses a foreign project-wizard link and names its target"; fi
rc=0; installer --force || rc=$?
if [ "$rc" -eq 0 ] && [ "$(readlink "$WIZARD_LINK")" = "$REPO/project-init.sh" ]; then pass "install.sh --force replaces a foreign project-wizard link"
else fail "install.sh --force exited $rc and left project-wizard -> '$(readlink "$WIZARD_LINK" || true)'"; fi

fresh_home; rc=0; installer --no-shell-rc || rc=$?
if [ "$rc" -ne 0 ]; then fail "install.sh --no-shell-rc exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ -e "$IHOME/.bashrc" ] || [ -e "$IHOME/.zshrc" ]; then fail "install.sh --no-shell-rc still wrote an rc file"
else pass "install.sh --no-shell-rc leaves the rc files alone"; fi

fresh_home; installer || true; rc=0; installer --uninstall --purge || rc=$?
if [ "$rc" -ne 0 ]; then fail "install.sh --uninstall --purge exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ -n "$(leftovers)" ]; then fail "install.sh --uninstall --purge left: $(leftovers)"
elif [ -e "$IHOME/.project-wizard" ]; then fail "install.sh --uninstall --purge kept ~/.project-wizard"
elif [ ! -f "$IHOME/.bashrc.bak" ]; then fail "install.sh --uninstall --purge saved no ~/.bashrc.bak"
else pass "install.sh --uninstall --purge leaves only .bak files"; fi
before="$(snapshot)"; rc=0; installer --uninstall --purge || rc=$?
if [ "$rc" -eq 0 ] && [ "$(snapshot)" = "$before" ]; then pass "a second install.sh --uninstall is a no-op"
else fail "a second install.sh --uninstall exited $rc or changed: $(diff <(echo "$before") <(snapshot) | tr '\n' ' ')"; fi

fresh_home; printf "alias ll='ls -l'\n" > "$IHOME/.bashrc"; installer || true; before="$(snapshot)"
rc=0; installer --uninstall --dry-run || rc=$?
if [ "$rc" -eq 0 ] && [ "$(snapshot)" = "$before" ]; then pass "install.sh --uninstall --dry-run changes nothing"
else fail "install.sh --uninstall --dry-run exited $rc or changed: $(diff <(echo "$before") <(snapshot) | tr '\n' ' ')"; fi
rc=0; installer --uninstall || rc=$?
if [ "$rc" -ne 0 ]; then fail "install.sh --uninstall (stdin closed) exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ ! -d "$IHOME/.project-wizard" ]; then fail "install.sh --uninstall without --purge deleted ~/.project-wizard with no TTY to ask"
elif [ -L "$WIZARD_LINK" ]; then fail "install.sh --uninstall kept this checkout's project-wizard link"
elif [ "$(cat "$IHOME/.bashrc")" != "alias ll='ls -l'" ]; then fail "install.sh --uninstall left ~/.bashrc as: $(tr '\n' '|' < "$IHOME/.bashrc")"
else pass "install.sh --uninstall restores ~/.bashrc and keeps ~/.project-wizard when it cannot ask"; fi

fresh_home; mkdir -p "$IHOME/.local/bin"; ln -s "$FOREIGN" "$WIZARD_LINK"
rc=0; installer --uninstall --purge || rc=$?
if [ "$rc" -eq 0 ] && [ "$(readlink "$WIZARD_LINK")" = "$FOREIGN" ]; then pass "install.sh --uninstall never removes a foreign project-wizard link"
else fail "install.sh --uninstall on a foreign link exited $rc and left project-wizard -> '$(readlink "$WIZARD_LINK" || true)'"; fi

exit "$FAILED"

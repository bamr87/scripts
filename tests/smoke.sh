#!/usr/bin/env bash
###############################################################################
# File: tests/smoke.sh
# Description: Offline regression smoke for the toolbelt's safety contract:
#              every --help is side-effect free, install.sh refuses unknown
#              options, and project-init.sh honors CREATE_GITHUB_REPO and
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

exit "$FAILED"

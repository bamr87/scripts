#!/usr/bin/env bash
###############################################################################
# File: tests/smoke.sh
# Description: Offline regression smoke for the toolbelt's safety contract:
#              every --help is side-effect free, install.sh refuses unknown
#              options, and project-init.sh honors CREATE_GITHUB_REPO and
#              PUSH_TO_GITHUB, and user input (prompt answers, .env and
#              --config files, --file-types, --max-depth, repo names) is
#              data that never runs. Runs in a throwaway HOME with a recording `gh`
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

# 4. Input is data, never shell (issue #29): prompt answers, ./.env and
#    --config files, --file-types, --max-depth and repo names never run a
#    command or add a find primary. $SANDBOX is where an injection would land.
SANDBOX="$WORK/inject"
export SANDBOX
reset_sandbox() { rm -rf "$SANDBOX"; mkdir -p "$SANDBOX"; }

# Feed one answer to project-init.sh's prompt_user and print what it stored.
prompt_value() {
    printf '%s\n' "$1" | HOME="$WORK/home" bash -c \
        'source "$1"; prompt_user "Question" "" ANSWER >/dev/null 2>&1; printf "%s" "$ANSWER"' _ "$REPO/project-init.sh"
}

reset_sandbox
# shellcheck disable=SC2016  # the $SANDBOX in the answer is the payload, expanded only if eval'd
injection='x'"'"'; touch "$SANDBOX/PWNED"; echo '"'"
got="$(prompt_value "$injection" || true)"
if [ -e "$SANDBOX/PWNED" ]; then fail "prompt_user executed its input"
elif [ "$got" != "$injection" ]; then fail "prompt_user stored [$got], expected the input verbatim"
else pass "prompt_user stores an injection attempt verbatim without running it"; fi

got="$(prompt_value "O'Brien's app" || true)"
if [ "$got" = "O'Brien's app" ]; then pass "prompt_user keeps apostrophes"
else fail "prompt_user stored [$got] for O'Brien's app"; fi

# Interactive mode reads ./.env: run the wizard from a directory whose .env
# carries a command substitution, then decline at the final confirmation.
reset_sandbox
mkdir -p "$WORK/envdir"
# shellcheck disable=SC2016  # literal payload
printf '%s\n' 'NON_INTERACTIVE=true' 'PROJECT_TYPE=custom' 'PROJECT_NAME=$(touch "$SANDBOX/PWNED")' > "$WORK/envdir/.env"
rc=0
(cd "$WORK/envdir" && printf '\n\n\n\n\nn\n' | HOME="$WORK/home" GIT_CONFIG_GLOBAL=/dev/null bash -c \
    'source "$1"; clear() { :; }; run_wizard' _ "$REPO/project-init.sh" >"$WORK/out.txt" 2>&1) || rc=$?
if [ -e "$SANDBOX/PWNED" ]; then fail "./.env was executed as shell"
elif ! grep -qF 'Project Name:     $(touch "$SANDBOX/PWNED")' "$WORK/out.txt"; then fail "./.env value not taken literally (exit $rc): $(grep 'Project Name' "$WORK/out.txt" || tail -3 "$WORK/out.txt")"
else pass "./.env is parsed as KEY=VALUE, never executed"; fi

reset_sandbox
# shellcheck disable=SC2016  # literal payload
printf '%s\n' 'CREATE_GITHUB_REPO=false' 'PROJECT_DESCRIPTION=$(touch "$SANDBOX/PWNED")' 'PATH=/nonexistent' > "$WORK/config.env"
rc=0; sandboxed "$WORK/home" env NON_INTERACTIVE=true PROJECT_TYPE=custom PROJECT_NAME=configured \
    PROJECT_DIR="$WORK/projects/configured" GITHUB_USERNAME=smoke GITHUB_EMAIL=smoke@example.invalid \
    bash "$REPO/project-init.sh" --config "$WORK/config.env" --non-interactive || rc=$?
if [ -e "$SANDBOX/PWNED" ]; then fail "--config file was executed as shell"
elif [ "$rc" -ne 0 ]; then fail "--config scaffold exited $rc: $(tail -3 "$WORK/out.txt")"
else pass "--config is parsed as data and ignores keys like PATH"; fi

reset_sandbox
rc=0; sandboxed "$WORK/home" bash "$REPO/FORKME/forkme.sh" --dry-run --no-fork --strategy filetype \
    --file-types 'md" -o -name "*' owner/repo || rc=$?
if [ "$rc" -ne 0 ] && grep -q "Invalid --file-types" "$WORK/out.txt"; then pass "forkme rejects a --file-types entry that is not a plain extension"
else fail "forkme accepted a crafted --file-types (exit $rc): $(tail -2 "$WORK/out.txt")"; fi

mkdir -p "$WORK/stash-empty"
rc=0; sandboxed "$WORK/home" bash "$REPO/STASHME/stashme.sh" --dry-run -d "$WORK/stash-empty" \
    --max-depth '1 -exec touch '"$SANDBOX"'/PWNED \;' || rc=$?
if [ -e "$SANDBOX/PWNED" ]; then fail "stashme --max-depth injected a find primary"
elif [ "$rc" -ne 0 ] && grep -q "Invalid --max-depth" "$WORK/out.txt"; then pass "stashme rejects a non-integer --max-depth"
else fail "stashme accepted a crafted --max-depth (exit $rc): $(tail -2 "$WORK/out.txt")"; fi

rc=0; sandboxed "$WORK/home" env GITHUB_USER=smoke bash "$REPO/git_init.sh" --headless -n "it's-a-test" --dry-run || rc=$?
expected="DRYRUN: mkdir -p $(printf '%q' "$WORK/home/github/it's-a-test")"
if [ "$rc" -eq 0 ] && grep -qF "$expected" "$WORK/out.txt"; then pass "git_init --dry-run prints printf %q-quoted commands"
else fail "git_init --dry-run (exit $rc) did not print [$expected]: $(grep DRYRUN "$WORK/out.txt" | head -2)"; fi

exit "$FAILED"

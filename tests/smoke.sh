#!/usr/bin/env bash
###############################################################################
# File: tests/smoke.sh
# Description: Offline regression smoke for the toolbelt's safety contract:
#              every --help is side-effect free, install.sh refuses unknown
#              options, project-init.sh honors CREATE_GITHUB_REPO and
#              PUSH_TO_GITHUB, and the --dry-run of git_init.sh, forkme.sh and
#              stashme.sh writes nothing and reaches no network, while a real
#              stash still completes. Runs in a throwaway HOME with recording
#              `gh` and `git` stubs, so nothing reaches GitHub or the caller's
#              dotfiles.
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

# A git that records every network subcommand (push, pull, fetch, clone,
# ls-remote) and swallows it, so a dry run that would reach a remote is caught
# without one; anything else runs the real git, found here before sandboxed()
# puts $WORK/bin first on PATH. GIT_STUB_PASSTHROUGH=1 records the call and
# runs it anyway, for runs against local bare remotes.
REAL_GIT="$(command -v git)"
{
    echo '#!/usr/bin/env bash'
    printf 'log=%q\nreal_git=%q\n' "$WORK/git-calls.log" "$REAL_GIT"
    cat <<'STUB'
sub=""; i=1
while [ "$i" -le "$#" ]; do
    case "${!i}" in
        -C|-c|--git-dir|--work-tree|--namespace) i=$((i + 2)) ;;
        -*) i=$((i + 1)) ;;
        *) sub="${!i}"; break ;;
    esac
done
case "$sub" in
    push|pull|fetch|clone|ls-remote)
        echo "git $*" >> "$log"
        [ "${GIT_STUB_PASSTHROUGH:-}" = 1 ] || exit 0 ;;
esac
exec "$real_git" "$@"
STUB
} > "$WORK/bin/git"
chmod +x "$WORK/bin/git"

# Run a command in a fresh sandbox HOME; prints nothing, returns its exit code.
sandboxed() {
    local home="$1"; shift
    rm -rf "$home"; mkdir -p "$home"
    : > "$WORK/gh-calls.log"; : > "$WORK/git-calls.log"
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

# 4. --dry-run changes nothing (issue #32): git_init.sh, forkme.sh and
#    stashme.sh exit 0 and print their plan, write nothing under HOME or the
#    working directory, and make no gh call and no git network call. A real
#    stash over dirty repos still reaches its summary.
# Run a command from a fresh, empty working directory in a fresh sandbox HOME.
in_scratch() {
    rm -rf "$WORK/cwd"; mkdir -p "$WORK/cwd"
    (cd "$WORK/cwd" && sandboxed "$WORK/home" "$@")
}
# Everything the last in_scratch run left behind: entries under HOME (~) and
# the working directory (.), then every recorded gh and git network call.
side_effects() {
    find "$WORK/home" "$WORK/cwd" -mindepth 1 | sed -e "s#$WORK/home#~#" -e "s#$WORK/cwd#.#"
    cat "$WORK/gh-calls.log" "$WORK/git-calls.log"
}
# Fixture repos are built with the real git, isolated from the caller's config
# and hooks: a repo with one commit, its own local bare origin and one
# untracked file.
fixture_git() { GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 "$REAL_GIT" "$@"; }
dirty_repo() {
    local repo="$1" remote="$2"
    fixture_git init -q --bare "$remote"
    fixture_git init -q -b main "$repo"
    fixture_git -C "$repo" config user.name smoke
    fixture_git -C "$repo" config user.email smoke@example.invalid
    fixture_git -C "$repo" commit -q --allow-empty -m init
    fixture_git -C "$repo" remote add origin "$remote"
    echo "work in progress" > "$repo/wip.txt"
}

rc=0; in_scratch env GITHUB_USER=smoke bash "$REPO/git_init.sh" --headless -n previewme --dry-run || rc=$?
left="$(side_effects | tr '\n' ' ')"
if [ "$rc" -ne 0 ]; then fail "git_init.sh --dry-run exited $rc: $(tail -3 "$WORK/out.txt")"
elif ! grep -qF "DRYRUN: Would run gh repo create smoke/previewme" "$WORK/out.txt"; then fail "git_init.sh --dry-run printed no gh repo create plan: $(tail -3 "$WORK/out.txt")"
elif [ -n "$left" ]; then fail "git_init.sh --dry-run left: $left"
else pass "git_init.sh --dry-run creates no repo directory and calls no gh or git network command"; fi

rc=0; in_scratch bash "$REPO/FORKME/forkme.sh" --dry-run --no-fork octocat/Hello-World || rc=$?
left="$(side_effects | tr '\n' ' ')"
if [ "$rc" -ne 0 ]; then fail "forkme.sh --dry-run exited $rc: $(tail -3 "$WORK/out.txt")"
elif ! grep -qF "[DRY RUN] Would clone: https://github.com/octocat/Hello-World.git" "$WORK/out.txt"; then fail "forkme.sh --dry-run printed no clone plan: $(tail -3 "$WORK/out.txt")"
elif [ -n "$left" ]; then fail "forkme.sh --dry-run left: $left"
else pass "forkme.sh --dry-run creates no forkme-workspace/ and clones nothing"; fi

dirty_repo "$WORK/stash-dry/r1" "$WORK/remotes/dry-r1.git"
rc=0; in_scratch bash "$REPO/STASHME/stashme.sh" --dry-run -d "$WORK/stash-dry" || rc=$?
left="$(side_effects | tr '\n' ' ')"
branches="$(fixture_git -C "$WORK/stash-dry/r1" branch --list 'stashme/*'; fixture_git -C "$WORK/remotes/dry-r1.git" branch --list 'stashme/*')"
if [ "$rc" -ne 0 ]; then fail "stashme.sh --dry-run exited $rc: $(tail -3 "$WORK/out.txt")"
elif ! grep -qF "[DRY RUN] Would create branch" "$WORK/out.txt"; then fail "stashme.sh --dry-run printed no branch plan: $(tail -3 "$WORK/out.txt")"
elif [ -n "$branches" ]; then fail "stashme.sh --dry-run created branches: $branches"
elif [ "$(fixture_git -C "$WORK/stash-dry/r1" status --porcelain)" != "?? wip.txt" ]; then fail "stashme.sh --dry-run changed the working tree: $(fixture_git -C "$WORK/stash-dry/r1" status --porcelain | tr '\n' ' ')"
elif [ -n "$left" ]; then fail "stashme.sh --dry-run left: $left"
else pass "stashme.sh --dry-run creates no stashme/* branch and pushes nothing"; fi

dirty_repo "$WORK/stash-real/r1" "$WORK/remotes/real-r1.git"
dirty_repo "$WORK/stash-real/r2" "$WORK/remotes/real-r2.git"
rc=0; in_scratch env GIT_STUB_PASSTHROUGH=1 bash "$REPO/STASHME/stashme.sh" -d "$WORK/stash-real" -b stashme/smoke || rc=$?
landed=""
for r in r1 r2; do
    if [ -n "$(fixture_git -C "$WORK/remotes/real-$r.git" branch --list stashme/smoke)" ]; then landed+="$r "; fi
done
if [ "$rc" -ne 0 ]; then fail "stashme.sh over two dirty repos exited $rc: $(tail -3 "$WORK/out.txt")"
elif ! grep -qE "Successfully pushed: +2$" "$WORK/out.txt"; then fail "stashme.sh summary: $(grep -E "Successfully" "$WORK/out.txt" | tr '\n' ' ')"
elif [ "$landed" != "r1 r2 " ]; then fail "stashme/smoke reached only these bare remotes: ${landed:-none}"
else pass "stashme.sh stashes two dirty repos, pushes both and reaches its summary"; fi

# A bare post-increment command returns status 1 when the counter was 0, and
# set -e then aborts the tool: what killed every stashme run (issue #32).
counters="$(cd "$REPO" && grep -nE '(^|[;&|[:space:]])\(\([[:space:]]*[A-Za-z_][A-Za-z0-9_]*(\+\+|--)[[:space:]]*\)\)' -- *.sh FORKME/forkme.sh STASHME/stashme.sh || true)"
if [ -z "$counters" ]; then pass "no tool bumps a counter with a bare post-increment that set -e turns into an exit"
else fail "post-increment commands abort under set -e when the counter is 0: $counters"; fi

exit "$FAILED"

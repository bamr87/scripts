#!/usr/bin/env bash
###############################################################################
# File: tests/smoke.sh
# Description: Offline regression smoke for the toolbelt's safety contract:
#              every --help is side-effect free, install.sh refuses unknown
#              options, writes nothing under --dry-run, never replaces or
#              removes a project-wizard that is not its own and --uninstall
#              reverses it, project-init.sh honors CREATE_GITHUB_REPO and
#              PUSH_TO_GITHUB, git_init.sh --no-push never creates a GitHub
#              repo, user input (prompt answers, .env and --config
#              files, --file-types, --max-depth, repo names) is data that never
#              runs, and the --dry-run of git_init.sh, forkme.sh and
#              stashme.sh writes nothing and reaches no network, while a real
#              stash still completes. The destructive tools (project-init.sh,
#              rename-directory.sh, create_package.sh) preview with --dry-run,
#              which a DRY_RUN=false in a sourced .env or --config cannot
#              cancel; rename-directory.sh runs unattended with --yes and says
#              what it already did when piped answers run out; and
#              create_package.sh refuses a non-empty target without --force.
#              Runs in a throwaway HOME with recording `gh`, `git` and
#              `docker` stubs, so nothing reaches GitHub, Docker or the
#              caller's dotfiles. Also holds the shell completions in
#              completions/ to each tool's --help: every long flag it lists,
#              and no other, is offered. Ctrl-C and SIGTERM stop forkme.sh
#              and stashme.sh with exit 130 / 143 after their cleanup.
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
# An npx that does nothing, so git_init.sh's degit template fallback stays offline.
printf '#!/usr/bin/env bash\nexit 0\n' > "$WORK/bin/npx"
chmod +x "$WORK/bin/npx"

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

# A docker that records every call and changes nothing; `ps` lists the
# containers named in DOCKER_STUB_PS (none by default).
cat > "$WORK/bin/docker" <<STUB
#!/usr/bin/env bash
echo "docker \$*" >> "$WORK/docker-calls.log"
if [ "\$1" = ps ] && [ -n "\${DOCKER_STUB_PS:-}" ]; then echo "\$DOCKER_STUB_PS"; fi
exit 0
STUB
chmod +x "$WORK/bin/docker"

# Run a command in a fresh sandbox HOME; prints nothing, returns its exit code.
sandboxed() {
    local home="$1"; shift
    rm -rf "$home"; mkdir -p "$home"
    : > "$WORK/gh-calls.log"; : > "$WORK/git-calls.log"; : > "$WORK/docker-calls.log"
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

# 4. git_init.sh --no-push is local only: no gh repo create, with or without a template.
for args in "" "-t octocat/template-repo"; do
    # shellcheck disable=SC2086  # $args is deliberately word-split into flags
    rc=0; sandboxed "$WORK/home" bash "$REPO/git_init.sh" --headless -n nopush -u smoke --license None --path "$WORK/repos" --no-push $args || rc=$?
    label="git_init.sh --no-push${args:+ $args}"
    if grep -q "repo create" "$WORK/gh-calls.log"; then fail "$label still called: $(cat "$WORK/gh-calls.log")"
    elif [ ! -d "$WORK/repos/nopush/.git" ]; then fail "$label (exit $rc) made no local repo: $(tail -3 "$WORK/out.txt")"
    else pass "$label never calls gh repo create"; fi
    rm -rf "$WORK/repos"
done
# 5. Shell completions (completions/, FR5): each file registers its command, and
#    `<command> --<TAB>` offers exactly the long flags the tool's --help lists, so
#    a flag added to or dropped from a tool fails here until its completion follows.
# Prints the words completions/<file> offers for a command line, one per line;
# the last word is the one being completed.
complete_words() {
    bash -c 'source "$1" || exit 1; shift
        func="$(complete -p "$1" 2>/dev/null | sed -n "s/.* -F \([^ ]*\) .*/\1/p")"
        [ -n "$func" ] || exit 1
        COMP_WORDS=("$@"); COMP_CWORD=$(($# - 1)); COMPREPLY=()
        "$func" "$1" "${COMP_WORDS[COMP_CWORD]}" "${COMP_WORDS[COMP_CWORD-1]}"
        if [ "${#COMPREPLY[@]}" -gt 0 ]; then printf "%s\n" "${COMPREPLY[@]}"; fi' _ "$REPO/completions/$1" "${@:2}"
}
ESC="$(printf '\033')"
long_flags() { sed "s/${ESC}\[[0-9;]*m//g" | grep -oE -- '--[a-z][a-z-]*' | sort -u || true; }

for spec in forkme:FORKME/forkme.sh stashme:STASHME/stashme.sh git-init:git_init.sh; do
    cmd="${spec%%:*}"; script="${spec#*:}"; file="$cmd.bash"
    if [ ! -f "$REPO/completions/$file" ]; then fail "completions/$file is missing"; continue; fi
    if ! bash -c 'source "$1" && complete -p "$2"' _ "$REPO/completions/$file" "$cmd" >/dev/null 2>&1; then
        fail "completions/$file does not register a completion for $cmd"; continue
    fi
    sandboxed "$WORK/home" bash "$REPO/$script" --help || true
    documented="$(long_flags < "$WORK/out.txt")"
    offered="$(complete_words "$file" "$cmd" -- | grep -E -- '^--' | sort -u || true)"
    missing="$(comm -23 <(echo "$documented") <(echo "$offered") | tr '\n' ' ')"
    extra="$(comm -13 <(echo "$documented") <(echo "$offered") | tr '\n' ' ')"
    if [ -z "$documented" ]; then fail "$script --help lists no long flags"
    elif [ -n "$missing$extra" ]; then fail "completions/$file drifted from $script --help: missing [${missing% }] extra [${extra% }]"
    else pass "completions/$file offers the $(echo "$documented" | wc -l | tr -d ' ') long flags of $script --help"; fi
done

# Values: forkme's strategies and tag modes, and directories (never files) for
# the arguments that name one, including stashme's positional after --restore.
mkdir -p "$WORK/tree/alpha" "$WORK/tree/beta"; : > "$WORK/tree/notes.txt"
expect_words() {   # <expected words> <file> <word>...; compared as sorted sets
    local want got; want="$(printf '%s\n' $1 | sort | tr '\n' ' ')"; shift
    got="$(cd "$WORK/tree" && complete_words "$@" | sort | tr '\n' ' ' || true)"
    if [ "$got" = "$want" ]; then pass "${*:2}<TAB> offers: ${want% }"
    else fail "${*:2}<TAB> offered [${got% }], want [${want% }]"; fi
}
expect_words "full shallow sparse toplevel structure filetype analysis mirror bundle metadata" forkme.bash forkme --strategy ""
expect_words "any all" forkme.bash forkme --tag-mode ""
expect_words "alpha beta" stashme.bash stashme --restore ""
expect_words "alpha beta" stashme.bash stashme -d ""
expect_words "alpha beta" git-init.bash git-init --path ""

# zsh: _toolbelt loads all three through bashcompinit, and the bash functions
# answer when zsh's compgen shim calls them (it runs them under sh emulation).
if command -v zsh >/dev/null 2>&1; then
    rc=0; sandboxed "$WORK/home" zsh -fc '
        autoload -U compinit && compinit -u -D
        source "$1/completions/_toolbelt" || exit 1
        for c in forkme stashme git-init; do
            [[ -n ${_comps[$c]} ]] || { print -r -- "no completion registered for $c"; exit 1; }
        done
        words=(forkme --strategy ""); CURRENT=3; COMP_WORDS=("${words[@]}"); COMP_CWORD=2
        compgen -F _forkme -- "" | paste -sd " " -' _ "$REPO" || rc=$?
    want="full shallow sparse toplevel structure filetype analysis mirror bundle metadata"
    if [ "$rc" -eq 0 ] && [ "$(cat "$WORK/out.txt")" = "$want" ]; then pass "zsh: completions/_toolbelt registers forkme, stashme and git-init"
    else fail "zsh: completions/_toolbelt (exit $rc): $(tail -3 "$WORK/out.txt")"; fi
else
    echo "skip zsh is not installed, so completions/_toolbelt was not loaded"
fi
# 6. install.sh: --dry-run writes nothing, a re-run adds no second PATH line, a
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
# 7. --dry-run changes nothing (issue #32): git_init.sh, forkme.sh and
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

# 8. The destructive tools preview and run unattended (issue #31, PRD FR3):
#    project-init.sh, rename-directory.sh and create_package.sh take --dry-run
#    (project-init.sh's survives a sourced DRY_RUN=false), rename-directory.sh
#    takes --yes / --backup / --no-backup with no stdin and reports a stop it
#    already made, and create_package.sh refuses a non-empty target unless
#    --force.
rc=0; in_scratch env NON_INTERACTIVE=true PROJECT_TYPE=custom PROJECT_NAME=dry \
    PROJECT_DIR="$WORK/projects/dry" GITHUB_USERNAME=smoke GITHUB_EMAIL=smoke@example.invalid \
    LICENSE=MIT SETUP_DOCKER=true SETUP_CI=true CREATE_GITHUB_REPO=true \
    bash "$REPO/project-init.sh" --non-interactive --dry-run || rc=$?
left="$(side_effects | tr '\n' ' ')"
if [ "$rc" -ne 0 ]; then fail "project-init.sh --dry-run exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ -e "$WORK/projects/dry" ]; then fail "project-init.sh --dry-run created PROJECT_DIR: $(find "$WORK/projects/dry" | tr '\n' ' ')"
elif ! grep -qE "gh repo create smoke/dry --public .*--push" "$WORK/out.txt"; then fail "project-init.sh --dry-run printed no gh repo create line: $(grep -i 'github' "$WORK/out.txt" | tr '\n' ' ')"
elif [ -n "$left" ]; then fail "project-init.sh --dry-run left: $left"
else pass "project-init.sh --dry-run prints its gh repo create plan, creates nothing and calls no gh"; fi

# in_scratch, but with ./.env copied from $1 (none if it is "-") and stdin read
# from the file $2 instead of /dev/null, for the interactive prompts.
interactive() {
    local dotenv="$1" answers="$2"; shift 2
    # shellcheck disable=SC2016  # expanded by the inner shell
    in_scratch bash -c 'if [ "$1" != - ]; then cp "$1" .env; fi; f="$2"; shift 2; exec "$@" < "$f"' _ "$dotenv" "$answers" "$@"
}
printf '\n%.0s' 1 2 3 4 5 6 7 8 9 10 > "$WORK/enter-x10"

# A sourced file cannot cancel --dry-run: a project's own .env (sourced by the
# interactive wizard) or a --config file that sets DRY_RUN=false is ignored.
cat > "$WORK/dry-env" <<EOF
DRY_RUN=false
NON_INTERACTIVE=true
PROJECT_TYPE=custom
PROJECT_NAME=envx
PROJECT_DIR=$WORK/projects/envx
GITHUB_USERNAME=smoke
GITHUB_EMAIL=smoke@example.invalid
CREATE_GITHUB_REPO=true
EOF
for mode in .env --config; do
    rm -rf "$WORK/projects/envx"; rc=0
    if [ "$mode" = .env ]; then
        # TERM: the interactive wizard starts with `clear`, which fails without one.
        interactive "$WORK/dry-env" "$WORK/enter-x10" env TERM=xterm bash "$REPO/project-init.sh" --dry-run || rc=$?
    else
        in_scratch bash "$REPO/project-init.sh" --non-interactive --dry-run --config "$WORK/dry-env" || rc=$?
    fi
    left="$(side_effects | { grep -vx '\./\.env' || true; } | tr '\n' ' ')"
    if [ "$rc" -ne 0 ]; then fail "project-init.sh --dry-run with DRY_RUN=false in $mode exited $rc: $(tail -3 "$WORK/out.txt")"
    elif [ -e "$WORK/projects/envx" ]; then fail "project-init.sh --dry-run with DRY_RUN=false in $mode created PROJECT_DIR: $(find "$WORK/projects/envx" -maxdepth 1 | sed "s#$WORK/##" | tr '\n' ' ')"
    elif ! grep -qE "gh repo create smoke/envx --public .*--push" "$WORK/out.txt"; then fail "project-init.sh --dry-run with DRY_RUN=false in $mode printed no gh repo create line: $(tail -3 "$WORK/out.txt")"
    elif [ -n "$left" ]; then fail "project-init.sh --dry-run with DRY_RUN=false in $mode left: $left"
    else pass "project-init.sh --dry-run stays a dry run when $mode sets DRY_RUN=false"; fi
done

# The wizard's own flag variable is not one of the keys an env file may set
# (the file is parsed as data, not sourced): a WIZARD_DRY_RUN=false in ./.env
# is ignored and the run stays a dry run.
{ cat "$WORK/dry-env"; echo "WIZARD_DRY_RUN=false"; } > "$WORK/dry-env-reset"
rm -rf "$WORK/projects/envx"; rc=0
interactive "$WORK/dry-env-reset" "$WORK/enter-x10" env TERM=xterm bash "$REPO/project-init.sh" --dry-run || rc=$?
left="$(side_effects | { grep -vx '\./\.env' || true; } | tr '\n' ' ')"
if [ "$rc" -ne 0 ]; then fail "project-init.sh --dry-run with WIZARD_DRY_RUN=false in ./.env exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ -e "$WORK/projects/envx" ] || [ -n "$left" ]; then fail "project-init.sh --dry-run with WIZARD_DRY_RUN=false in ./.env left: $left"
elif ! grep -qE "gh repo create smoke/envx --public .*--push" "$WORK/out.txt"; then fail "project-init.sh --dry-run with WIZARD_DRY_RUN=false in ./.env printed no gh repo create line: $(tail -3 "$WORK/out.txt")"
else pass "project-init.sh --dry-run stays a dry run when ./.env sets WIZARD_DRY_RUN=false"; fi

# rename-directory.sh: a dirty git repo, and a running container named after it.
mkdir -p "$WORK/rename"
dirty_repo "$WORK/rename/app" "$WORK/remotes/app.git"
backups() { find "$WORK/rename" -mindepth 1 -maxdepth 1 -name "$1-backup-*" | sed "s#$WORK/rename/##"; }

rc=0; in_scratch env DOCKER_STUB_PS=app-web-1 bash "$REPO/rename-directory.sh" --dry-run "$WORK/rename/app" "$WORK/rename/app2" || rc=$?
left="$(side_effects | tr '\n' ' ')"
if [ "$rc" -ne 0 ]; then fail "rename-directory.sh --dry-run exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ ! -d "$WORK/rename/app" ] || [ -e "$WORK/rename/app2" ]; then fail "rename-directory.sh --dry-run moved the directory"
elif [ -n "$(backups app)" ]; then fail "rename-directory.sh --dry-run made a backup: $(backups app)"
elif grep -q "docker stop" "$WORK/docker-calls.log"; then fail "rename-directory.sh --dry-run stopped containers: $(cat "$WORK/docker-calls.log")"
elif ! grep -qF "[DRY RUN] Would rename" "$WORK/out.txt"; then fail "rename-directory.sh --dry-run printed no plan: $(tail -3 "$WORK/out.txt")"
elif [ -n "$left" ]; then fail "rename-directory.sh --dry-run left: $left"
else pass "rename-directory.sh --dry-run checks a dirty repo and changes nothing, without a prompt"; fi

rc=0; in_scratch env DOCKER_STUB_PS=app-web-1 bash "$REPO/rename-directory.sh" "$WORK/rename/app" "$WORK/rename/app2" || rc=$?
if [ "$rc" -eq 0 ]; then fail "rename-directory.sh with no stdin to answer its prompts exited 0"
elif [ ! -d "$WORK/rename/app" ] || [ -e "$WORK/rename/app2" ]; then fail "rename-directory.sh with no stdin moved the directory"
elif grep -q "docker stop" "$WORK/docker-calls.log"; then fail "rename-directory.sh with no stdin stopped containers"
else pass "rename-directory.sh with no stdin to answer stops before changing anything"; fi

# One piped "yes" stops the container; the next prompt finds no answer, and the
# message must own up to the stop instead of claiming nothing changed.
echo yes > "$WORK/yes-once"
rc=0; interactive - "$WORK/yes-once" env DOCKER_STUB_PS=app-web-1 bash "$REPO/rename-directory.sh" "$WORK/rename/app" "$WORK/rename/app2" || rc=$?
if [ "$rc" -eq 0 ]; then fail "rename-directory.sh with one answer for two prompts exited 0"
elif [ ! -d "$WORK/rename/app" ] || [ -e "$WORK/rename/app2" ]; then fail "rename-directory.sh with one answer moved the directory"
elif ! grep -q "docker stop app-web-1" "$WORK/docker-calls.log"; then fail "rename-directory.sh did not act on the piped yes: $(cat "$WORK/docker-calls.log")"
elif grep -q "Nothing was changed" "$WORK/out.txt" || ! grep -qF "already stopped: app-web-1" "$WORK/out.txt"; then fail "rename-directory.sh misreports what it changed: $(grep -A2 'No answer' "$WORK/out.txt" | tr '\n' ' ')"
else pass "rename-directory.sh out of answers names the containers it already stopped"; fi

rc=0; in_scratch env DOCKER_STUB_PS=app-web-1 bash "$REPO/rename-directory.sh" --yes --no-backup "$WORK/rename/app" "$WORK/rename/app2" || rc=$?
if [ "$rc" -ne 0 ]; then fail "rename-directory.sh --yes --no-backup exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ -e "$WORK/rename/app" ] || [ ! -d "$WORK/rename/app2/.git" ]; then fail "rename-directory.sh --yes --no-backup did not rename app to app2"
elif [ -n "$(backups app)" ]; then fail "rename-directory.sh --no-backup made a backup: $(backups app)"
elif ! grep -q "docker stop app-web-1" "$WORK/docker-calls.log"; then fail "rename-directory.sh --yes did not stop the container: $(cat "$WORK/docker-calls.log")"
else pass "rename-directory.sh --yes --no-backup renames unattended, stopping the related container"; fi

rc=0; in_scratch bash "$REPO/rename-directory.sh" --yes "$WORK/rename/app2" "$WORK/rename/app3" || rc=$?
if [ "$rc" -ne 0 ]; then fail "rename-directory.sh --yes exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ -e "$WORK/rename/app2" ] || [ ! -d "$WORK/rename/app3" ]; then fail "rename-directory.sh --yes did not rename app2 to app3"
elif [ -z "$(backups app2)" ]; then fail "rename-directory.sh --yes made no backup"
else pass "rename-directory.sh --yes renames unattended and backs up first"; fi

rc=0; in_scratch bash "$REPO/create_package.sh" --dry-run pkg || rc=$?
left="$(side_effects | tr '\n' ' ')"
if [ "$rc" -ne 0 ]; then fail "create_package.sh --dry-run exited $rc: $(tail -3 "$WORK/out.txt")"
elif ! grep -qF "git clone --depth=1 https://github.com/microsoft/python-package-template.git" "$WORK/out.txt"; then fail "create_package.sh --dry-run printed no clone step: $(tail -3 "$WORK/out.txt")"
elif [ -n "$left" ]; then fail "create_package.sh --dry-run left: $left"
else pass "create_package.sh --dry-run creates no ~/github/pkg and clones nothing"; fi

# create_package.sh in a sandbox whose ~/github/pkg already holds existing.txt.
over_existing_pkg() {
    # shellcheck disable=SC2016  # $HOME is the sandbox's, expanded by the inner shell
    sandboxed "$WORK/home" bash -c 'mkdir -p "$HOME/github/pkg" && echo keep > "$HOME/github/pkg/existing.txt" && exec bash "$@"' \
        _ "$REPO/create_package.sh" "$@"
}
rc=0; over_existing_pkg pkg || rc=$?
if [ "$rc" -eq 0 ]; then fail "create_package.sh overlaid a non-empty ~/github/pkg without --force"
elif [ "$(cat "$WORK/home/github/pkg/existing.txt")" != keep ] || [ -e "$WORK/home/github/pkg/.git" ]; then fail "create_package.sh changed a non-empty ~/github/pkg it refused"
elif [ -s "$WORK/git-calls.log" ]; then fail "create_package.sh cloned before refusing: $(cat "$WORK/git-calls.log")"
else pass "create_package.sh refuses a non-empty ~/github/pkg and leaves it untouched"; fi

rc=0; over_existing_pkg --force pkg || rc=$?
if [ "$rc" -ne 0 ]; then fail "create_package.sh --force exited $rc: $(tail -3 "$WORK/out.txt")"
elif [ "$(cat "$WORK/home/github/pkg/existing.txt")" != keep ] || [ ! -d "$WORK/home/github/pkg/.git" ]; then fail "create_package.sh --force did not bootstrap over ~/github/pkg"
elif ! grep -q "git clone --depth=1" "$WORK/git-calls.log"; then fail "create_package.sh --force never cloned the template"
else pass "create_package.sh --force bootstraps over a non-empty ~/github/pkg"; fi
# 9. Input is data, never shell (issue #29): prompt answers, ./.env and
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

# 10. Ctrl-C and SIGTERM stop the tool (issue #62): forkme.sh and stashme.sh
#     exit 130 / 143 instead of running cleanup and carrying on with the next
#     step, and cleanup still removes forkme's temporary clone. A slow git
#     stub, ahead of the recording one on PATH, logs each push and clone as it
#     starts (a clone also creates its target) and then sleeps, so the signal
#     lands while the tool waits on it.
mkdir -p "$WORK/slowbin"
{
    echo '#!/usr/bin/env bash'
    printf 'log=%q\nreal_git=%q\n' "$WORK/slow-calls.log" "$REAL_GIT"
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
    push) echo "push $PWD" >> "$log"; sleep 2; exit 0 ;;
    clone) dest="${!#}"; mkdir -p "$dest"; echo "clone $dest" >> "$log"; sleep 2; exit 0 ;;
esac
exec "$real_git" "$@"
STUB
} > "$WORK/slowbin/git"
chmod +x "$WORK/slowbin/git"

# Start a tool in the background from a fresh working directory and sandbox
# HOME, send it SIG as soon as the slow stub logs its first network call, and
# return the tool's exit status. Job control (set -m) keeps the background job
# from inheriting an ignored SIGINT, which a script could not then trap.
interrupted() {
    local sig="$1"; shift
    rm -rf "${WORK:?}/cwd" "${WORK:?}/home"; mkdir -p "$WORK/cwd" "$WORK/home"
    : > "$WORK/slow-calls.log"
    (
        set -m
        cd "$WORK/cwd" || exit 99
        HOME="$WORK/home" PATH="$WORK/slowbin:$WORK/bin:$PATH" GIT_CONFIG_GLOBAL=/dev/null \
            "$@" </dev/null >"$WORK/out.txt" 2>&1 &
        pid=$!
        for _ in $(seq 100); do [ -s "$WORK/slow-calls.log" ] && break; sleep 0.1; done
        kill -"$sig" "$pid"
        wait "$pid"
    )
}

for spec in INT:130 TERM:143; do
    sig="${spec%%:*}"; want="${spec#*:}"

    rm -rf "$WORK/stash-sig"
    dirty_repo "$WORK/stash-sig/r1" "$WORK/remotes/sig-r1.git"
    dirty_repo "$WORK/stash-sig/r2" "$WORK/remotes/sig-r2.git"
    rc=0; interrupted "$sig" bash "$REPO/STASHME/stashme.sh" -d "$WORK/stash-sig" -b stashme/sig || rc=$?
    pushes="$(grep -c '^push ' "$WORK/slow-calls.log" || true)"
    if [ "$rc" -ne "$want" ]; then fail "stashme.sh after SIG$sig exited $rc, not $want: $(tail -3 "$WORK/out.txt" | tr '\n' ' ')"
    elif [ "$pushes" -ne 1 ]; then fail "stashme.sh kept going after SIG$sig: $pushes pushes started"
    else pass "stashme.sh stops on SIG$sig with exit $want after the first push"; fi

    rc=0; interrupted "$sig" bash "$REPO/FORKME/forkme.sh" --no-fork --strategy bundle owner/repo || rc=$?
    temps="$(find "$WORK/cwd" -name '*_temp' | sed "s#$WORK/cwd#.#" | tr '\n' ' ')"
    if ! grep -q '^clone ' "$WORK/slow-calls.log"; then fail "forkme.sh --strategy bundle never reached its clone: $(tail -3 "$WORK/out.txt" | tr '\n' ' ')"
    elif [ "$rc" -ne "$want" ]; then fail "forkme.sh after SIG$sig exited $rc, not $want: $(tail -3 "$WORK/out.txt" | tr '\n' ' ')"
    elif [ -n "$temps" ]; then fail "forkme.sh left its temporary clone after SIG$sig: $temps"
    else pass "forkme.sh stops on SIG$sig with exit $want and removes its _temp clone"; fi
done

exit "$FAILED"

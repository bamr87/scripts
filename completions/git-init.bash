# shellcheck shell=bash
###############################################################################
# File: completions/git-init.bash
# Description: Tab completion for git-init (git_init.sh): every flag, the
#              --license and --scaffold values, and directories for --path.
#              tests/smoke.sh fails if the long flags offered here stop
#              matching `git_init.sh --help`.
# Author: IT-Journey Scripts Team
# Created: 2026-11-16
# Version: 1.0.0
#
# Usage:
#   source completions/git-init.bash    # bash; zsh loads it through _toolbelt
###############################################################################

# Append compgen's matches to COMPREPLY one per line, so a name with spaces
# stays one match. Works in bash 3.2+ and under zsh's bashcompinit.
_git_init_add() {
    local word
    while IFS= read -r word; do
        if [ -n "$word" ]; then COMPREPLY+=("$word"); fi
    done < <(compgen "$@")
}

_git_init() {
    local cur="${COMP_WORDS[COMP_CWORD]}" prev=""
    if [ "$COMP_CWORD" -gt 0 ]; then prev="${COMP_WORDS[COMP_CWORD-1]}"; fi
    COMPREPLY=()

    case "$prev" in
        --path)
            _git_init_add -d -- "$cur"
            return 0 ;;
        --license)
            _git_init_add -W "MIT Apache-2.0 None" -- "$cur"
            return 0 ;;
        --scaffold)
            _git_init_add -W "none jekyll python node minimal" -- "$cur"
            return 0 ;;
        -n|--name|-u|--user|-d|--desc|--gitignore|-t|--template)
            # Free-form values (a name, a login, a description, gitignore.io types, owner/repo): nothing to offer.
            return 0 ;;
    esac

    if [[ "$cur" == -* ]]; then
        _git_init_add -W "--name -n --user -u --desc -d --private -p --path
            --license --gitignore --scaffold --template -t --headless --no-push
            --dry-run --help -h" -- "$cur"
    fi
    # The positional argument is the repository name: nothing local to offer.
    return 0
}

complete -o filenames -F _git_init git-init git_init.sh

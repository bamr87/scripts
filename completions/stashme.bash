# shellcheck shell=bash
###############################################################################
# File: completions/stashme.bash
# Description: Tab completion for stashme (STASHME/stashme.sh): every flag,
#              directories for -d/--dir and for the base-directory argument
#              (also after --restore and --cleanup, which take no value), and
#              files for --summary. tests/smoke.sh fails if the long flags
#              offered here stop matching `stashme.sh --help`.
# Author: IT-Journey Scripts Team
# Created: 2026-11-16
# Version: 1.0.0
#
# Usage:
#   source completions/stashme.bash     # bash; zsh loads it through _toolbelt
###############################################################################

# Append compgen's matches to COMPREPLY one per line, so a name with spaces
# stays one match. Works in bash 3.2+ and under zsh's bashcompinit.
_stashme_add() {
    local word
    while IFS= read -r word; do
        if [ -n "$word" ]; then COMPREPLY+=("$word"); fi
    done < <(compgen "$@")
}

_stashme() {
    local cur="${COMP_WORDS[COMP_CWORD]}" prev=""
    if [ "$COMP_CWORD" -gt 0 ]; then prev="${COMP_WORDS[COMP_CWORD-1]}"; fi
    COMPREPLY=()

    case "$prev" in
        -d|--dir)
            _stashme_add -d -- "$cur"
            return 0 ;;
        --summary)
            _stashme_add -f -- "$cur"
            return 0 ;;
        --max-depth|-b|--branch|--prefix|--suffix|-m|--message)
            # Free-form values (a number, a branch name or part of one, a message): nothing to offer.
            return 0 ;;
    esac

    if [[ "$cur" == -* ]]; then
        _stashme_add -W "--help -h --version --dir -d --max-depth --include-hidden
            --branch -b --prefix --suffix --message -m --no-push --force -f
            --list -l --restore -r --cleanup --interactive -i --verbose -v
            --quiet -q --dry-run --summary" -- "$cur"
    else
        # The positional argument is the base directory to search.
        _stashme_add -d -- "$cur"
    fi
    return 0
}

complete -o filenames -F _stashme stashme stashme.sh

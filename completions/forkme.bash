# shellcheck shell=bash
###############################################################################
# File: completions/forkme.bash
# Description: Tab completion for forkme (FORKME/forkme.sh): every flag, the
#              10 --strategy names, the --tag-mode values, and directories for
#              --target and --work-dir. tests/smoke.sh fails if the long flags
#              offered here stop matching `forkme.sh --help`.
# Author: IT-Journey Scripts Team
# Created: 2026-11-16
# Version: 1.0.0
#
# Usage:
#   source completions/forkme.bash      # bash; zsh loads it through _toolbelt
###############################################################################

# Append compgen's matches to COMPREPLY one per line, so a name with spaces
# stays one match. Works in bash 3.2+ and under zsh's bashcompinit.
_forkme_add() {
    local word
    while IFS= read -r word; do
        if [ -n "$word" ]; then COMPREPLY+=("$word"); fi
    done < <(compgen "$@")
}

_forkme() {
    local cur="${COMP_WORDS[COMP_CWORD]}" prev=""
    if [ "$COMP_CWORD" -gt 0 ]; then prev="${COMP_WORDS[COMP_CWORD-1]}"; fi
    COMPREPLY=()

    case "$prev" in
        --strategy)
            _forkme_add -W "full shallow sparse toplevel structure filetype analysis mirror bundle metadata" -- "$cur"
            return 0 ;;
        --tag-mode)
            _forkme_add -W "any all" -- "$cur"
            return 0 ;;
        --target|--work-dir)
            _forkme_add -d -- "$cur"
            return 0 ;;
        --depth|--branch|--file-types|--include|--exclude|--sparse-paths|--tags|--user|--org)
            # Free-form values (a number, a branch, remote paths, topics, a login): nothing to offer.
            return 0 ;;
    esac

    if [[ "$cur" == -* ]]; then
        _forkme_add -W "--strategy --depth --branch --no-fork --target --work-dir
            --file-types --include --exclude --sparse-paths --analyze --analyze-only
            --stats --dry-run --verbose --interactive -i --clone-all --tags --tag-mode
            --fork --user --org --help -h --version -v" -- "$cur"
    fi
    # The positional argument is a repository URL or owner/repo: nothing local to offer.
    return 0
}

complete -o filenames -F _forkme forkme forkme.sh

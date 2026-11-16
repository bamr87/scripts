#!/bin/bash
# File: install.sh
# Description: Installer for the Project Initialization Wizard, wiring project-init.sh into a per-user CLI with PATH updates and example config; --uninstall reverses it
# Author: Amr Abdel-Motaleb <amr.abdel@gmail.com>
# Created: 2025-11-13
# Last Modified: 2026-11-15
# Version: 1.2.0
#
# Dependencies:
# - bash 4+
# - ln, mkdir, chmod, cp, rm, readlink, awk, mktemp
# - A POSIX-compliant shell startup file (~/.zshrc or ~/.bashrc)
#
# Container Requirements:
# - Base Image: bash-compatible Linux image (e.g. debian:stable, ubuntu:22.04)
# - Volumes: $HOME/.local/bin (optional bind for global CLI); $HOME/.project-wizard for user config
# - Environment: HOME must be set for the target user
#
# Usage:
#   ./install.sh [--dry-run] [--no-shell-rc] [--force]
#     Installs the Project Initialization Wizard under ~/.project-wizard,
#     ensures project-init.sh is executable, and exposes a project-wizard
#     command on your PATH (via ~/.local/bin).
#
#   ./install.sh --uninstall [--dry-run] [--no-shell-rc] [--purge]
#     Reverses the install: removes ~/.local/bin/project-wizard only if it
#     points to this checkout, removes the PATH block from ~/.zshrc and
#     ~/.bashrc (each saved as <rc>.bak first), and asks before deleting
#     ~/.project-wizard (--purge deletes it without asking).
#
#   ./install.sh -h|--help
#     Prints every flag; that list is the authoritative one.
#
#   WHICH INSTALLER DO I WANT?
#     This is the STANDALONE path — for users who cloned only this repo.
#     It deliberately wires up project-init.sh alone.
#
#     If you have the bamr87/bamr87 hub checked out, use its bootstrap
#     instead (`./tools/setup.sh`): its setup_script_cli_tools() marks every
#     *.sh here executable and symlinks the FULL set into ~/.local/bin —
#     forkme, stashme, git-init, project-wizard, rename-dir, create-package.
#     That is a strict superset of this script for CLI installation. Don't
#     run both: when ~/.local/bin/project-wizard already exists and is not
#     this checkout's link (the hub's, say), this script stops and prints
#     where it points; --force replaces it. What this script adds on top is
#     the ~/.project-wizard config directory and the .env.example copy,
#     which the hub does not create.
#
#   ENV NOTES:
#     - The rc file is chosen from your login shell ($SHELL):
#     - zsh (the macOS default) -> PATH is appended to ~/.zshrc
#     - bash -> PATH is appended to ~/.bashrc
#     - any other shell, or --no-shell-rc -> nothing is appended; add
#       ~/.local/bin to PATH yourself
#
# Design Notes:
#   - set -euo pipefail: the first failed write stops the run instead of
#     printing success over it
#   - Every flag is parsed, and a foreign project-wizard refused, before
#     anything is written, so --help, a typo or a refusal never installs
#   - Every write goes through run(), an argv runner (never eval) that
#     --dry-run turns into a shell-quoted printout
#   - Safe to re-run: directory creation, chmod and the symlink are
#     idempotent, and the PATH block is appended only once (its marker line
#     is checked first); a second --uninstall changes nothing

set -euo pipefail

RC_MARKER='# Project Wizard PATH'
# Written literally: the shell expands $PATH and $HOME when it reads the rc file.
# shellcheck disable=SC2016
RC_EXPORT='export PATH="$PATH:$HOME/.local/bin"'

show_help() {
    cat << EOF
Usage: $(basename "$0") [--dry-run] [--no-shell-rc] [--force]
       $(basename "$0") --uninstall [--dry-run] [--no-shell-rc] [--purge]

Installs the Project Initialization Wizard for the current user:
  - creates ~/.project-wizard/ (with templates/ and a copy of .env.example)
  - makes project-init.sh executable
  - symlinks it as ~/.local/bin/project-wizard (creating ~/.local/bin)
  - appends a PATH line to ~/.zshrc or ~/.bashrc, chosen from \$SHELL (once)

Options:
  --dry-run      Print every write (directory, chmod, symlink, rc edit, copy,
                 removal) and change nothing
  --no-shell-rc  Leave ~/.zshrc and ~/.bashrc alone; put ~/.local/bin on your
                 PATH yourself
  --force        Replace an existing ~/.local/bin/project-wizard that is not
                 this checkout's link. Without it, install stops, prints where
                 the existing one points, and writes nothing.
  --uninstall    Reverse the install: remove ~/.local/bin/project-wizard only
                 if it points to this checkout's project-init.sh, remove the
                 PATH block from ~/.zshrc and ~/.bashrc (copying each to
                 <rc>.bak first), and ask before deleting ~/.project-wizard/
                 (kept, with a note, when stdin is not a terminal). A second
                 run changes nothing.
  --purge        With --uninstall: delete ~/.project-wizard/ without asking
  -h, --help     Show this help and exit

If you have the bamr87/bamr87 hub checked out, run its ./tools/setup.sh
instead; it installs every tool in this repo.
EOF
}

usage_error() {
    echo "❌ $*" >&2
    show_help >&2
    exit 1
}

DRY_RUN=false
NO_SHELL_RC=false
FORCE=false
UNINSTALL=false
PURGE=false

# Parse every flag before touching anything, so --help (or a typo) never installs.
while [ $# -gt 0 ]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        --dry-run) DRY_RUN=true ;;
        --no-shell-rc) NO_SHELL_RC=true ;;
        --force) FORCE=true ;;
        --uninstall) UNINSTALL=true ;;
        --purge) PURGE=true ;;
        *) usage_error "Unknown option: $1" ;;
    esac
    shift
done

if [ "$PURGE" = true ] && [ "$UNINSTALL" = false ]; then
    usage_error "--purge only applies to --uninstall"
fi
if [ "$FORCE" = true ] && [ "$UNINSTALL" = true ]; then
    usage_error "--force only applies to install: --uninstall never removes a project-wizard that points outside this checkout"
fi
if [ -z "${HOME:-}" ] || [ ! -d "$HOME" ]; then
    echo "❌ HOME is unset or not a directory" >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$SCRIPT_DIR/project-init.sh"
WIZARD_DIR="$HOME/.project-wizard"
BIN_DIR="$HOME/.local/bin"
LINK="$BIN_DIR/project-wizard"

# Run one write, given as argv (never a string to eval). Under --dry-run,
# print it shell-quoted instead of running it.
run() {
    if [ "$DRY_RUN" = true ]; then
        local line
        line="$(printf '%q ' "$@")"
        echo "DRYRUN: ${line% }"
    else
        "$@"
    fi
}

# A success line for a write that really happened; silent under --dry-run.
ok() {
    [ "$DRY_RUN" = true ] || echo "✅ $*"
}

# Print a file path with its directory resolved physically (symlinks, ..),
# or fail when that directory does not exist.
canonical() {
    local dir
    dir="$(cd "$(dirname "$1")" 2>/dev/null && pwd -P)" || return 1
    printf '%s/%s\n' "$dir" "$(basename "$1")"
}

# True when ~/.local/bin/project-wizard is a symlink to this checkout's
# project-init.sh, however the link spells that path.
link_is_ours() {
    local dest
    [ -L "$LINK" ] || return 1
    dest="$(readlink "$LINK")"
    case $dest in
        /*) ;;
        *) dest="$BIN_DIR/$dest" ;;
    esac
    [ "$dest" = "$TARGET" ] && return 0
    [ "$(canonical "$dest" || true)" = "$(canonical "$TARGET")" ]
}

link_exists() {
    [ -e "$LINK" ] || [ -L "$LINK" ]
}

describe_link() {
    if [ -L "$LINK" ]; then
        echo "a symlink to $(readlink "$LINK")"
    elif [ -d "$LINK" ]; then
        echo "a directory"
    else
        echo "a regular file"
    fi
}

append_path_block() {
    printf '\n%s\n%s\n' "$RC_MARKER" "$RC_EXPORT" >> "$1"
}

# Copy stdin to stdout without the block append_path_block writes: the marker
# line, the export line right after it and the blank line right before it.
strip_path_block() {
    awk -v marker="$RC_MARKER" -v export_line="$RC_EXPORT" '
        { line[NR] = $0 }
        END {
            for (i = 1; i <= NR; i++) {
                if (line[i] != marker) continue
                drop[i] = 1
                if (i > 1 && line[i - 1] == "") drop[i - 1] = 1
                if (i < NR && line[i + 1] == export_line) drop[i + 1] = 1
            }
            for (i = 1; i <= NR; i++) if (!(i in drop)) print line[i]
        }'
}

# Rewrite an rc file in place without the PATH block. Writing through it
# (rather than mv over it) keeps its permissions, and keeps a symlinked rc
# file (a dotfile manager's) a symlink.
remove_path_block() {
    local tmp
    tmp="$(mktemp)"
    strip_path_block < "$1" > "$tmp"
    cat "$tmp" > "$1"
    rm -f "$tmp"
}

# <rc>.bak, or a timestamped .bak when that one is taken, so an earlier
# backup (yours or a previous uninstall's) is never overwritten.
backup_path() {
    if [ -e "$1.bak" ] || [ -L "$1.bak" ]; then
        printf '%s.%s.bak\n' "$1" "$(date +%Y%m%d-%H%M%S)"
    else
        printf '%s.bak\n' "$1"
    fi
}

do_install() {
    # Decide about an existing project-wizard before writing anything, so a
    # refusal leaves HOME exactly as it was.
    local relink=true
    if link_is_ours; then
        relink=false
    elif link_exists; then
        if [ -d "$LINK" ] && [ ! -L "$LINK" ]; then
            echo "❌ $LINK is a directory; move it aside and re-run" >&2
            exit 1
        fi
        if [ "$FORCE" = false ]; then
            echo "❌ $LINK already exists and is $(describe_link)." >&2
            echo "   install.sh will not replace it. If it is the hub's tools/setup.sh link, keep it: that installs every tool here." >&2
            echo "   To point project-wizard at $TARGET instead, re-run with --force." >&2
            exit 1
        fi
        echo "⚠️  --force: replacing $LINK ($(describe_link))"
    fi

    echo "🚀 Installing Project Initialization Wizard..."

    # Create wizard directory (idempotent)
    echo "📁 Creating wizard directory..."
    run mkdir -p "$WIZARD_DIR/templates"

    # Ensure core wizard script is executable
    echo "🔧 Setting permissions..."
    run chmod +x "$TARGET"

    # Create the symlink in the user's local bin for CLI access (creating
    # ~/.local/bin first: it does not exist on a fresh account)
    if [ "$relink" = true ]; then
        echo "🔗 Creating symlink in ~/.local/bin..."
        run mkdir -p "$BIN_DIR"
        # -n: replace an existing link itself, never follow it into a directory
        run ln -sfn "$TARGET" "$LINK"
        ok "Symlink created at ~/.local/bin/project-wizard"
    else
        echo "✅ ~/.local/bin/project-wizard already points to this checkout"
    fi

    # Detect the user's login shell and update its rc file so project-wizard is
    # available on new shells. This script always runs under bash (shebang), so
    # $ZSH_VERSION/$BASH_VERSION would describe the installer, not the user.
    local shell_config="" shell_name="${SHELL:-}"
    shell_name="${shell_name##*/}"
    case $shell_name in
        zsh)  shell_config="$HOME/.zshrc" ;;
        bash) shell_config="$HOME/.bashrc" ;;
    esac

    if [ "$NO_SHELL_RC" = true ]; then
        echo "⏭️  --no-shell-rc: leaving your shell rc files alone; add \$HOME/.local/bin to your PATH yourself"
        shell_config=""
    elif [ -z "$shell_config" ]; then
        echo "⚠️  Unrecognised login shell '${SHELL:-unset}': add \$HOME/.local/bin to your PATH manually"
    elif grep -qF "$RC_MARKER" "$shell_config" 2>/dev/null; then
        echo "✅ Shell configuration already updated"
    else
        echo "📝 Updating shell configuration: appending '$RC_MARKER' and '$RC_EXPORT'..."
        run append_path_block "$shell_config"
        ok "Updated $shell_config"
    fi

    # Copy example configuration for users to customize defaults
    if [ -f "$SCRIPT_DIR/.env.example" ]; then
        echo "📋 Installing example configuration..."
        run cp "$SCRIPT_DIR/.env.example" "$WIZARD_DIR/.env.example"
        ok "Example configuration installed to $WIZARD_DIR/.env.example"
    fi

    echo ""
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 Dry run: nothing was written. Re-run without --dry-run to install."
        return 0
    fi

    echo "✨ Installation complete!"
    echo ""
    echo "🎯 Quick Start:"
    echo "   1. Run 'source ${shell_config:-<your shell rc file>}' to update your PATH (if needed)"
    echo "   2. Run 'project-wizard' from anywhere to start the wizard"
    echo "   3. Or run '${SCRIPT_DIR}/project-init.sh' directly"
    echo ""
    echo "📖 For more information:"
    echo "   - Run 'project-wizard --help' to see all options"
    echo "   - Check ${SCRIPT_DIR}/README.md for documentation"
    echo "   - Copy $WIZARD_DIR/.env.example to .env for custom defaults"
    echo "   - Undo all of this with '${SCRIPT_DIR}/install.sh --uninstall'"
    echo ""
    echo "Happy coding! 🚀"
}

do_uninstall() {
    echo "🧹 Uninstalling Project Initialization Wizard..."

    # 1. The symlink, only when it is this checkout's: a hub or other clone's
    #    project-wizard is not ours to remove.
    if link_is_ours; then
        echo "🔗 Removing ~/.local/bin/project-wizard..."
        run rm -f "$LINK"
        ok "Removed ~/.local/bin/project-wizard"
    elif link_exists; then
        echo "⚠️  Keeping $LINK: it is $(describe_link), not this checkout's project-init.sh"
    else
        echo "✅ No ~/.local/bin/project-wizard to remove"
    fi

    # 2. The PATH block, from both rc files: the login shell may have changed
    #    since the install.
    if [ "$NO_SHELL_RC" = true ]; then
        echo "⏭️  --no-shell-rc: leaving ~/.zshrc and ~/.bashrc alone"
    else
        local rc bak found=false
        for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
            if [ ! -f "$rc" ] || ! grep -qxF "$RC_MARKER" "$rc"; then
                continue
            fi
            found=true
            bak="$(backup_path "$rc")"
            echo "📝 Removing the PATH block from $rc (backup: $bak)..."
            run cp -p "$rc" "$bak"
            if [ ! -L "$rc" ] && [ -z "$(strip_path_block < "$rc" | tr -d '[:space:]')" ]; then
                # Nothing but the block install.sh wrote: install created this file.
                run rm -f "$rc"
                ok "Removed $rc (it held only the PATH block; the copy is in $bak)"
            else
                run remove_path_block "$rc"
                ok "Updated $rc"
            fi
        done
        if [ "$found" = false ]; then
            echo "✅ No PATH block in ~/.zshrc or ~/.bashrc"
        fi
    fi

    # 3. ~/.project-wizard holds your templates and config, so it is never
    #    deleted without --purge or a yes at the prompt.
    if [ ! -e "$WIZARD_DIR" ] && [ ! -L "$WIZARD_DIR" ]; then
        echo "✅ No ~/.project-wizard to remove"
    elif [ "$PURGE" = true ]; then
        echo "🗑️  --purge: deleting ~/.project-wizard..."
        run rm -rf "$WIZARD_DIR"
        ok "Deleted ~/.project-wizard"
    elif [ -t 0 ] && [ "$DRY_RUN" = true ]; then
        echo "📁 Would ask before deleting ~/.project-wizard (--purge deletes it without asking)"
    elif [ -t 0 ]; then
        local reply=""
        read -r -p "Delete ~/.project-wizard (your templates and config)? [y/N] " reply || reply=""
        case $reply in
            [yY]|[yY][eE][sS])
                run rm -rf "$WIZARD_DIR"
                ok "Deleted ~/.project-wizard"
                ;;
            *) echo "📁 Kept ~/.project-wizard" ;;
        esac
    else
        echo "📁 Kept ~/.project-wizard (no terminal to ask): delete it yourself, or re-run with --uninstall --purge"
    fi

    echo ""
    if [ "$DRY_RUN" = true ]; then
        echo "🔍 Dry run: nothing was changed. Re-run without --dry-run to uninstall."
    else
        echo "✨ Uninstall complete. Shells already open keep their PATH until you restart them."
    fi
}

if [ "$UNINSTALL" = true ]; then
    do_uninstall
else
    do_install
fi

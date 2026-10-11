#!/bin/bash
# Install Omazed and initialize theme/font syncing for the current user.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
BIN_DIR="$HOME/.local/bin"
OMARCHY_HOOKS_DIR="$HOME/.config/omarchy/hooks"
THEME_SET_HOOK="$OMARCHY_HOOKS_DIR/theme-set"

log() { printf '[INFO] %s\n' "$*"; }
info() { log "$@"; }
error() { printf '[ERROR] %s\n' "$*" >&2; }

usage() {
    cat <<EOF
Usage: $0 [--help]

Installs Omazed into ~/.local/bin, configures Omarchy v3/v4 hooks,
and synchronizes the Zed theme and font. No additional setup is needed.
Run as your desktop user, without sudo. Requires Zed, jq and perl.
Existing unrelated Zed themes and hooks are preserved.
EOF
}

detect_omarchy_version() {
    local version=""
    if command -v omarchy-version >/dev/null 2>&1; then
        version=$(omarchy-version 2>/dev/null || true)
        version=${version%%.*}
    fi
    if [[ "$version" =~ ^[0-9]+$ ]] && (( version >= 4 )); then
        printf 'v4\n'
    elif [[ -d "$HOME/.local/state/omarchy/current/theme" ]]; then
        printf 'v4\n'
    else
        printf 'v3\n'
    fi
}

check_requirements() {
    if (( EUID == 0 )); then
        error "Run ./install.sh as your desktop user, without sudo."
        return 1
    fi
    local cmd file found=false
    for cmd in jq perl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Missing dependency: $cmd. Install it with: sudo pacman -S --needed jq perl"
            return 1
        fi
    done
    for cmd in zeditor zed zedit zed-editor; do
        if command -v "$cmd" >/dev/null 2>&1; then found=true; break; fi
    done
    if [[ "$found" != true ]]; then
        error "Zed is required. Install Zed first, then rerun this script."
        return 1
    fi
    local theme_dir="$HOME/.config/omarchy/current/theme"
    if [[ "$(detect_omarchy_version)" == v4 ]]; then
        theme_dir="$HOME/.local/state/omarchy/current/theme"
    fi
    if [[ ! -f "$theme_dir/colors.toml" && ! -f "$theme_dir/alacritty.toml" ]]; then
        error "Current Omarchy palette not found: $theme_dir"
        return 1
    fi
    for file in omazed omazed-generator.sh omazed-font.sh omazed-theme.tpl; do
        if [[ ! -f "$SCRIPT_DIR/$file" ]]; then
            error "Missing installation file: $SCRIPT_DIR/$file"
            return 1
        fi
    done
}

setup_omarchy_hook() {
    log "Setting up omarchy hook integration..."

    local hook_marker_start="# >>> omazed hook - do not edit >>>"
    local hook_marker_end="# <<< omazed hook - do not edit <<<"
    local version
    version=$(detect_omarchy_version)

    if [[ "$version" == "v4" ]]; then
        # v4 uses .d directory
        local hook_dir="$OMARCHY_HOOKS_DIR/theme-set.d"
        mkdir -p "$hook_dir"
        local v4_hook_file="$hook_dir/omazed"

        cat > "$v4_hook_file" << EOF
#!/bin/bash
exec $(printf '%q' "$BIN_DIR/omazed") set "\${1:-}"
EOF
        chmod +x "$v4_hook_file"
        local font_hook_dir="$OMARCHY_HOOKS_DIR/font-set.d"
        mkdir -p "$font_hook_dir"
        local v4_font_hook_file="$font_hook_dir/omazed"

        cat > "$v4_font_hook_file" << EOF
#!/bin/bash
exec $(printf '%q' "$BIN_DIR/omazed") set-font "\${1:-}"
EOF
        chmod +x "$v4_font_hook_file"
        info "Created v4 omarchy font hook: $v4_font_hook_file"

        info "Created v4 omarchy hook: $v4_hook_file"

        # Cleanup old v3 hook if it exists
        if [[ -f "$THEME_SET_HOOK" ]] && grep -q "$hook_marker_start" "$THEME_SET_HOOK" 2>/dev/null; then
            sed -i "/$hook_marker_start/,/$hook_marker_end/d" "$THEME_SET_HOOK"
            info "Removed legacy v3 omazed hook"
        fi

        log "Omarchy hook configured (v4) ✓"
    else
        # v3 uses single file injection
        mkdir -p "$OMARCHY_HOOKS_DIR"

        if [[ ! -f "$THEME_SET_HOOK" ]]; then
            cat > "$THEME_SET_HOOK" << 'EOF'
#!/bin/bash

# This hook is called with the snake-cased name of the theme that has just been set.
EOF
            chmod +x "$THEME_SET_HOOK"
            info "Created theme-set hook file"
        fi

        if grep -q "$hook_marker_start" "$THEME_SET_HOOK" 2>/dev/null; then
            sed -i "/$hook_marker_start/,/$hook_marker_end/d" "$THEME_SET_HOOK"
            info "Removed old omazed hook"
        fi

        local hook_command
        printf -v hook_command '%q set "${1:-}"' "$BIN_DIR/omazed"

        cat >> "$THEME_SET_HOOK" << EOF

$hook_marker_start
$hook_command
$hook_marker_end
EOF

        chmod +x "$THEME_SET_HOOK"
        local font_hook="$OMARCHY_HOOKS_DIR/font-set"
        if [[ ! -f "$font_hook" ]]; then
            printf '#!/bin/bash\n' > "$font_hook"
        fi
        sed -i "/$hook_marker_start/,/$hook_marker_end/d" "$font_hook"
        local font_command
        printf -v font_command '%q set-font "${1:-}"' "$BIN_DIR/omazed"
        printf '\n%s\n%s\n%s\n' "$hook_marker_start" "$font_command" "$hook_marker_end" >> "$font_hook"
        chmod +x "$font_hook"
        log "Omarchy theme and font hooks configured (v3) ✓"
    fi
}


main() {
    case "${1:-}" in
        -h|--help) usage; return 0 ;;
        "") ;;
        *) error "Unknown option: $1"; usage; return 1 ;;
    esac
    if (( $# > 1 )); then error "Too many arguments"; return 1; fi
    check_requirements
    mkdir -p "$BIN_DIR"
    local file
    for file in omazed omazed-generator.sh omazed-font.sh; do
        install -m 755 "$SCRIPT_DIR/$file" "$BIN_DIR/$file"
    done
    install -m 644 "$SCRIPT_DIR/omazed-theme.tpl" "$BIN_DIR/omazed-theme.tpl"
    setup_omarchy_hook
    if ! "$BIN_DIR/omazed" sync; then
        error "Files and hooks installed, but initial sync failed. Fix the error above and rerun ./install.sh."
        return 1
    fi
    if [[ ! -s "$HOME/.config/zed/themes/omazed.json" ]]; then
        error "Initial sync did not generate the Zed theme. Run $BIN_DIR/omazed sync to diagnose."
        return 1
    fi
    log "Installation complete: Zed theme and font syncing are active."
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) log "For manual commands, add ~/.local/bin to PATH or use $BIN_DIR/omazed." ;;
    esac
}

main "$@"

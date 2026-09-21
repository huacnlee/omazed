#!/bin/bash

# Omazed Uninstaller
# Cleanly removes the live theme switching tool and all associated components

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BIN_DIR="$HOME/.local/bin"
DATA_DIR="$HOME/.local/share/omazed"
OMARCHY_HOOKS_DIR="$HOME/.config/omarchy/hooks"
THEME_SET_HOOK="$OMARCHY_HOOKS_DIR/theme-set"
FONT_SET_D_HOOK="$OMARCHY_HOOKS_DIR/font-set.d/omazed"
SYNC_SCRIPT="$BIN_DIR/omazed"
GENERATOR_SCRIPT="$BIN_DIR/omazed-generator.sh"
FONT_SCRIPT="$BIN_DIR/omazed-font.sh"
TEMPLATE_FILE="$BIN_DIR/omazed-theme.tpl"

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

# Print banner
print_banner() {
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║                     Omazed Uninstaller                    ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
}

# Check what's currently installed
check_installation() {
    info "Checking current installation..."

    local found_components=()

    if [[ -f "$SYNC_SCRIPT" ]]; then
        found_components+=("Theme Sync Script")
    fi

    if [[ -f "$GENERATOR_SCRIPT" ]]; then
        found_components+=("Theme Generator Script")
    fi

    if [[ -f "$TEMPLATE_FILE" ]]; then
        found_components+=("Theme Template File")
    fi


    if [[ -f "$THEME_SET_HOOK" ]] && grep -q "omazed" "$THEME_SET_HOOK" 2>/dev/null; then
        found_components+=("Omarchy Hook")
    fi

    if [[ -d "$DATA_DIR" ]]; then
        found_components+=("Application Data Directory")
    fi


    if [[ ${#found_components[@]} -eq 0 ]]; then
        warn "No installation components found"
        return 1
    else
        local IFS=', '
        info "Found components: ${found_components[*]}"
        return 0
    fi
}

# Remove theme watcher script and generator
remove_sync_script() {
    info "Removing theme sync script..."

    # Remove the sync script
    if [[ -f "$SYNC_SCRIPT" ]]; then
        if rm -f "$SYNC_SCRIPT"; then
            log "Theme sync script removed ✓"
        else
            error "Failed to remove theme sync script"
        fi
    fi

    # Remove the generator script
    if [[ -f "$GENERATOR_SCRIPT" ]]; then
        if rm -f "$GENERATOR_SCRIPT"; then
            rm -f "$FONT_SCRIPT"
            log "Theme generator script removed ✓"
        else
            error "Failed to remove theme generator script"
        fi
    fi

    if [[ -f "$TEMPLATE_FILE" ]]; then
        if rm -f "$TEMPLATE_FILE"; then
            log "Theme template file removed ✓"
        else
            error "Failed to remove theme template file"
        fi
    fi
}

# Remove application data directory and logs
remove_data_dir() {
    info "Removing application data directory..."

    if [[ -d "$DATA_DIR" ]]; then
        if rm -rf "$DATA_DIR"; then
            log "Application data directory removed ✓"
        else
            error "Failed to remove application data directory"
        fi
    fi
}

remove_omarchy_hook() {
    info "Removing omarchy hook integration..."

    local hook_marker_start="# >>> omazed hook - do not edit >>>"
    local hook_marker_end="# <<< omazed hook - do not edit <<<"
    rm -f "$FONT_SET_D_HOOK"

    if [[ -f "$THEME_SET_HOOK" ]]; then
        if grep -q "$hook_marker_start" "$THEME_SET_HOOK" 2>/dev/null; then
            sed -i "/$hook_marker_start/,/$hook_marker_end/d" "$THEME_SET_HOOK"
            log "Removed omazed hook ✓"
        else
            log "No omazed hook found in theme-set file"
        fi
    else
        log "No hook file found"
    fi
}

# Check for Zed dev extension
check_zed_themes() {
    info "Checking for generated Zed theme..."

    local generated_theme="$HOME/.config/zed/themes/omazed.json"

    if [[ -f "$generated_theme" ]]; then
        warn "Found generated theme: $generated_theme"
        info "You can remove it manually if desired"
    else
        log "No generated theme found ✓"
    fi
}

# Clean up any remaining configuration
cleanup_config() {
    info "Cleaning up configuration..."

    # Check if Zed settings were modified
    local zed_settings="$HOME/.config/zed/settings.json"
    if [[ -f "$zed_settings" ]] && grep -q "omazed\|omarchy" "$zed_settings" 2>/dev/null; then
        warn "Zed settings may contain omazed-related themes"
        info "You may want to manually review: $zed_settings"
    fi

    log "Configuration cleanup completed ✓"
}



# Print post-uninstall information
print_completion() {
    cat << EOF

╔═══════════════════════════════════════════════════════════╗
║                  UNINSTALLATION COMPLETE!                 ║
╚═══════════════════════════════════════════════════════════╝

🗑️  Omazed has been removed successfully!

📋 WHAT WAS REMOVED:

   ✓ Theme sync script
   ✓ Theme generator script
   ✓ Omarchy hook integration (if present)
   ✓ Application data directory and logs

📝 MANUAL CLEANUP (optional):

   • Remove generated theme if desired:
     - ~/.config/zed/themes/omazed.json

   • Review Zed settings if needed:
     - ~/.config/zed/settings.json

🔄 TO REINSTALL:

   Run the install script again:
   ./install.sh

Thanks for using Omazed! 👋

EOF
}

# Error handling
handle_error() {
    error "Uninstallation encountered an error on line $1"
    error "Some components may not have been removed completely"
    exit 1
}

# Main uninstallation function
main() {
    print_banner

    # Parse arguments
    local force=false
    local yes=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force=true
                FORCE=true
                shift
                ;;

            -y|--yes)
                yes=true
                shift
                ;;
            -h|--help)
                cat << EOF
Omazed Uninstaller

Usage: $0 [OPTIONS]

Options:
    -h, --help      Show this help message
    --force         Force removal without prompts

    -y, --yes       Answer yes to all prompts

Examples:
    $0              # Interactive uninstallation
    $0 --force      # Force removal of all components

EOF
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    log "Starting Omazed uninstallation..."

    # Check what's installed
    if ! check_installation; then
        info "Nothing to uninstall. Omazed appears to already be removed."
        exit 0
    fi

    # Confirm uninstallation
    if [[ "$force" != "true" && "$yes" != "true" ]]; then
        echo
        read -p "Are you sure you want to uninstall Omazed? (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            info "Uninstallation cancelled by user"
            exit 0
        fi
    fi



    # Remove components
    remove_omarchy_hook
    remove_sync_script
    remove_data_dir
    check_zed_themes
    cleanup_config

    print_completion

    log "Uninstallation completed successfully! 🗑️"
}

# Set up error handling
trap 'handle_error $LINENO' ERR

# Run main uninstallation
main "$@"

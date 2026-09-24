# Omazed

Live theme switching for Zed in Omarchy. Omazed generates a Zed theme from the current Omarchy palette and keeps it in sync when you change themes.

## Features

- Live theme syncing through Omarchy hooks
- Generates `~/.config/zed/themes/omazed.json` from `colors.toml` (fallback to `alacritty.toml`)
- Support for Omarchy v3 and Omarchy v4 (Quattro)
- One-time Zed theme selection on first run after install/update
- Lightweight Bash workflow

## Installation

**Note**: Omazed is automatically installed on Omarchy (3.8.0 onwards) when installing Zed via the **Install > Editor** menu.

### AUR (Recommended)

```bash
yay -S omazed

# Complete setup
omazed setup
```

### Manual

```bash
git clone https://github.com/aps6/omazed.git
cd omazed
./install.sh
```

## How It Works

1) Omazed ensures the Omarchy hook triggers `omazed set "$1"` on theme changes.
2) On first run after install/update, Omazed sets the Zed theme to `Omazed` once.
3) On every theme change, Omazed regenerates `~/.config/zed/themes/omazed.json` from the current Omarchy palette.

## Usage

```bash
# Set up hooks and sync once
omazed setup

# Regenerate theme for the current Omarchy palette
omazed sync

# Generate theme (used by Omarchy hook)
omazed set "theme-name"
```

## Theme Generation

Omazed's generator reads:
- `~/.local/state/omarchy/current/theme/colors.toml` (Omarchy v4)
- `~/.config/omarchy/current/theme/colors.toml` (Omarchy v3)
- Falls back to `alacritty.toml` when needed

The output is written directly to:
- `~/.config/zed/themes/omazed.json`

### How the palette maps to Zed

The mapping follows Omarchy's own application templates (the VS Code, Helix and
Alacritty themes generated from the same `colors.toml`) and the shell's
`shell.toml` control states:

- **Surfaces** — the file tree, title bar, status bar, tab bar, toolbar, panels
  and popovers all sit on `background`. Omarchy chrome is one flat canvas; only
  the active editor line uses the raised `lighter_background`.
- **Borders** — panel edges, tab bar, pane splits and popover edges use
  foreground at 12%, the shell's `PanelSeparator` hairline, which lands close
  to the `muted` 40% the VS Code template uses for its splits. De-emphasized
  dividers use foreground at 8%. Focus uses `accent`, like the Hyprland
  active-window border. The theme's `muted` (v3: bright black) drives indent
  guides, wrap guides and rendered whitespace.
- **Interactive states** — hover, pressed and disabled fills are
  foreground-tinted alphas (8% / 22% / 4%), the same values as the shell's
  `[controls]` section. Selection uses the theme's `selection` color when it
  ships one.
- **Cursor** — `bright_foreground` (falling back to `cursor`, then
  `foreground`), matching the Alacritty and VS Code templates.
- **Search matches** — `yellow` at 20% / 40%, as in the VS Code template.
- **Secondary text** — `dark_foreground`, brightened toward `foreground` until
  it meets WCAG 4.5:1 against the background.

## Notes

- Omazed only sets the Zed theme to `Omazed` once on first run after install/update.
- After that, it never overrides your Zed theme selection.

## Troubleshooting

```bash
# Verify hook exists (Omarchy v4)
ls -la ~/.config/omarchy/hooks/theme-set.d/omazed

# Verify hook exists (Omarchy v3)
ls -la ~/.config/omarchy/hooks/theme-set

# Manual regeneration test
omazed sync
```

## Support

- Issues: https://github.com/aps6/omazed/issues
- Discussions: https://github.com/aps6/omazed/discussions

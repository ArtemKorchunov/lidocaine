#!/bin/bash
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
BIN_DIR="$HOME/.local/bin"
WITH_APP=1
WITH_SKILL=0

for arg in "$@"; do
  case "$arg" in
    --no-app) WITH_APP=0 ;;
    --skill) WITH_SKILL=1 ;;
    -h|--help)
      echo "Usage: ./install.sh [--no-app] [--skill]"
      echo "  --no-app   only install the lidocaine command, skip the menu bar app"
      echo "  --skill    also install the Claude Code skill into ~/.claude/skills/lidocaine"
      exit 0 ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

[ "$(uname -s)" = Darwin ] || { echo "Lidocaine only runs on macOS." >&2; exit 1; }

chmod +x "$REPO/scripts/lidocaine.sh" "$REPO/menubar/build.sh"
mkdir -p "$BIN_DIR"
ln -sf "$REPO/scripts/lidocaine.sh" "$BIN_DIR/lidocaine"
echo "Installed command: $BIN_DIR/lidocaine -> $REPO/scripts/lidocaine.sh"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "Note: $BIN_DIR is not on your PATH. Add this to ~/.zshrc:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

"$REPO/scripts/lidocaine.sh" heal-agent install

if [ "$WITH_APP" = 1 ]; then
  if ! command -v swiftc >/dev/null 2>&1; then
    echo "swiftc not found. Install the Xcode Command Line Tools (xcode-select --install) and re-run, or use --no-app." >&2
    exit 1
  fi
  "$REPO/menubar/build.sh"
fi

if [ "$WITH_SKILL" = 1 ]; then
  mkdir -p "$HOME/.claude/skills"
  rm -rf "$HOME/.claude/skills/lidocaine"
  ln -s "$REPO/claude-skill" "$HOME/.claude/skills/lidocaine"
  echo "Installed Claude Code skill: ~/.claude/skills/lidocaine"
fi

cat <<EOF

Done. Next steps:
  lidocaine status                 check that it works
  lidocaine on                     keep the Mac awake with the lid closed
  lidocaine off                    normal sleep again

Optional, one time:
  lidocaine install-nopasswd       switch without a password (allows only lidocaine's exact pmset/powermetrics commands)
EOF

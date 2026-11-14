#!/bin/bash
set -u

if command -v lidocaine >/dev/null 2>&1; then
  lidocaine off --all 2>/dev/null || true
fi
launchctl bootout "gui/$(id -u)/com.oddproblems.lidocaine.heal" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/com.oddproblems.lidocaine.heal.plist"
pkill -x LidocaineBar 2>/dev/null || true
rm -rf "$HOME/Applications/Lidocaine.app" "$HOME/Applications/Insomnia.app"
pkill -x InsomniaBar 2>/dev/null || true
rm -f "$HOME/.local/bin/lidocaine" "$HOME/.local/bin/insomnia"
[ -L "$HOME/.claude/skills/lidocaine" ] && rm -f "$HOME/.claude/skills/lidocaine"
if [ -f /etc/sudoers.d/lidocaine ] || [ -f /etc/sudoers.d/insomnia ]; then
  echo "Removing the no-password rule (asks for your password):"
  sudo rm -f /etc/sudoers.d/lidocaine /etc/sudoers.d/insomnia
fi
echo "Lidocaine removed. If it is still listed under System Settings > General > Login Items, remove it there."

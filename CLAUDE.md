# Lidocaine: start plan for Claude

This repo is Lidocaine, a macOS tool that keeps a MacBook working with the lid closed, with a thermal and battery watchdog, an optional Claude Code Remote Control bridge for phone access, and a menu bar app. Read README.md for what it does.

When the user asks you to set up, install, or use Lidocaine, follow this plan.

## 1. Install

1. Confirm the machine is a Mac: `uname -s` must print `Darwin`.
2. Check the Swift compiler for the menu bar app: `command -v swiftc`. If it is missing, tell the user to run `xcode-select --install` themselves, or continue with `--no-app`.
3. From the repo root run `./install.sh`. Add `--skill` if the user wants Claude Code to drive Lidocaine in future sessions. The installer links `~/.local/bin/lidocaine` to this repo, so the repo folder must stay where it is.
4. If the installer says `~/.local/bin` is not on PATH, offer the line it prints for `~/.zshrc`.
5. Verify with `lidocaine status`. It needs no admin rights.

## 2. Admin rights

`on`, `off` and `toggle` change sleep settings and need admin rights. You cannot type the user's password, and you should not try (`sudo -S`, askpass helpers and similar are off limits).

- Run `on`/`off` in the user's own terminal (for example through a terminal tool that opens a tab they can type into), or give them the command to run.
- If they want no prompts, suggest the one-time `lidocaine install-nopasswd` and let them run it. Explain that it allows only Lidocaine's exact `pmset`/`powermetrics` command lines. Never write a sudoers rule that covers the script itself: it lives in a user-writable folder.
- After `install-nopasswd`, `lidocaine nopasswd-status` exits 0 and you can run `on`/`off` yourself.

## 3. Everyday use

- Start: `lidocaine on` (options: `--hours N`, `--low-power`, `--max-temp C`, `--min-battery P`).
- With phone access: `lidocaine on --remote <folder>`. Pick the folder the user wants to work in from the phone, or `--remote all` when they want every recent folder (and all their chats) reachable from the phone; `lidocaine recent-dirs` lists folders of recent Claude Code sessions. Phone access needs the `claude` CLI signed in with a claude.ai plan.
- Stop: `lidocaine off`. Phone access keeps running so phone chats stay connected; `lidocaine off --all` or `lidocaine remote-off` stops it.
- Update: `lidocaine update` moves the cloned folder to the latest release (the highest `vX.Y.Z` tag) and rebuilds the menu bar app if its code changed (`--check` only reports). If it says the folder has local changes, ask the user before stashing them.
- Check: `lidocaine status` (human) or `lidocaine state` (key=value). Report plainly: running or not, sleep disabled or not, lid, battery %, battery temperature, thermal pressure, phone access.

## 4. Safety answers

If the user worries about heat, run `lidocaine status` and give the real numbers. Battery temperature under 35 °C is normal, 35 to 40 °C is warm, and the watchdog stops at 45 °C. Thermal pressure "Nominal" is the lowest level. Remind them to keep the Mac on a hard surface or stand, never in a bag or on a bed. Background and sources are in docs/closed-lid-safety.md.

## 5. Troubleshooting

- Menu bar icon missing on a notched MacBook: the right side of the menu bar has limited room and overflowing items hide behind the notch. The app pins itself 260 pt from the right edge; other wide items (meeting titles, etc.) may need to be removed from the menu bar.
- `lidocaine status` warns that sleep is disabled with no watchdog: the heal agent fixes it within a minute if it is installed (`lidocaine heal-agent status`) and the no-password rule is in place; otherwise run `lidocaine off`, or `lidocaine heal-agent install`.
- Phone chats show "Remote Control disconnected": the Mac slept or Remote Control was stopped. Wake the Mac, or run `lidocaine remote-on <same folder>` to reconnect preserved sessions.
- Logs: `/tmp/lidocaine-watchdog.log`, `/tmp/lidocaine-remote.d/*.log` (one per phone folder); a folder that failed to start keeps its log in `~/Library/Logs/Lidocaine/`, and `lidocaine status` lists them.

## Working on the code

- `scripts/lidocaine.sh` is bash 3.2 compatible (macOS default) and runs with `set -u`: guard empty arrays with `${arr[@]+"${arr[@]}"}`.
- Background processes started for the menu bar app must not hold the caller's stdout/stderr open, or the app waits forever. Redirect the whole subshell, not only the inner command.
- After changing anything in `menubar/`, run `menubar/build.sh`; it rebuilds and relaunches the app.
- Releases: installed copies (the menu bar app's auto-update and `lidocaine update`) follow the newest `vX.Y.Z` tag, not `main`. A pushed commit reaches nobody until it is released, the maintainer's own Mac included. After pushing changes to `main`, ask the user whether to publish a release. If yes, bump the version (patch for fixes, minor for features), and run `gh release create vX.Y.Z --target main --title "Lidocaine X.Y" --notes-file <notes>` with plain-language notes on what changed for users. Then `lidocaine update` installs it.

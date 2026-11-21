# Lidocaine

<img src="assets/app-icon.png" width="96" align="right" alt="Lidocaine icon">

**Numbs your MacBook's lid, so your Claude Code habit keeps running.** A macOS menu bar app that keeps a Mac awake with the lid closed, safely. (Formerly called Insomnia; an existing install moves over by itself on its next update.)

Keep your MacBook working with the lid closed, without an external display, while macOS keeps managing the fans and thermal throttling. A watchdog puts the Mac to sleep if it gets too hot, the battery runs low, or a time limit passes.

It is built for leaving long jobs running (AI coding agents, builds, downloads, renders) while the laptop sits closed on a desk or stand. Optionally it also starts [Claude Code Remote Control](https://code.claude.com/docs/en/remote-control), so you can continue and **start new Claude Code sessions on your Mac from your phone** while the lid is shut.

| Off | On | Switching |
|---|---|---|
| <img src="assets/menu-asleep.png" width="72" alt="closed sleeping eye"> | <img src="assets/menu-awake.png" width="72" alt="open eye with the Claude spark as its iris"> | <img src="assets/menu-waking.png" width="72" alt="half-open waking eye"> |

## What it does

- **Lid closed, still running.** `pmset -a disablesleep 1` stops lid-close sleep, and `caffeinate -ims` stops idle sleep. The display is allowed to turn off.
- **Cooling untouched.** Fans, SMC thermal control and CPU/GPU throttling are never changed. macOS cools the Mac exactly as with the lid open.
- **Rests when nothing is running.** It watches your Claude Code and Codex sessions, background subagents included. While one is working, or phone access is on, or the lid is open, the Mac stays awake. Once the lid is closed, phone access is off and no agent has worked for 5 minutes (`LIDOCAINE_IDLE_MINUTES`), it rests: sleep is allowed and the Mac sleeps. Lidocaine stays on, so opening the lid wakes it straight back up; there is nothing to switch. It reads only the sessions' own transcript files on your Mac to see whether a turn is still running; nothing is sent anywhere. `lidocaine agents` shows how many are working. If a scheduled Claude task is due before the time limit, it stays up for that task and rests after it has run (the Claude app doesn't store schedules where Lidocaine can read them, so it goes by when each task last ran; tasks that run more often than every 3 hours don't count). `lidocaine next-task` shows the one it would wait for. A sleeping Mac can't start work on its own, so phone access keeps it awake: that way your phone can always reach it. A time limit still applies on top.
- **Morning report.** When a session of 15 minutes or more ends, it notes what your agents did: how many worked, for how long, the tokens they used, and whether one hit the usage limit. The menu bar app shows it once you open the lid ("While you were away"), and `lidocaine report` prints it.
- **Watchdog.** Every 30 seconds it checks thermal pressure (`powermetrics`), battery temperature and battery level. It stops and puts the Mac to sleep when:
  - thermal pressure reaches Trapping or worse, or stays Heavy for 15 minutes in a row (`LIDOCAINE_HEAVY_MINUTES`; brief Heavy spikes are normal macOS throttling under load),
  - the battery passes 45 °C (`--max-temp`),
  - the charge drops under 20% on battery power (`--min-battery`),
  - the optional `--hours` limit runs out. That also stops phone access, so a timed session ends fully. `lidocaine set-hours N` changes the limit of a running session (counted from now, 0 = no limit).
- **Always restores sleep.** Stopping it in any normal way (`lidocaine off`, Ctrl+C, a tripped limit) switches normal sleep back on. Even a crash, a `kill -9` of the watchdog or a reboot mid-session can't leave sleep disabled: a small login agent (`lidocaine heal-agent`, set up by the installer) runs `lidocaine heal` at login and every minute, and if sleep is disabled with no watchdog alive it switches sleep back on (and sleeps the Mac if the lid is closed). Restoring on its own needs the no-password rule below; without it the agent notifies you instead.
- **Locks the screen when the lid closes** (menu bar app). A locked Mac keeps running everything; only sleep stops work.
- **Phone access** (optional). `--remote DIR` starts `claude remote-control` in DIR, so the Claude mobile app (Code tab) or claude.ai/code can open and create sessions that run on this Mac. `--remote all` does this in every recent Claude folder at once (up to 8, `LIDOCAINE_REMOTE_MAX`; the home folder is skipped because Remote Control never saves trust there), one server per folder named `<Mac> · <folder>`, so the phone can open and start chats in any of them. `--remote` can also be repeated, and `lidocaine remote-on DIR...|all` adds folders to a running setup. A folder whose server can't start (for example an untrusted folder) is reported and skipped. By default each new phone chat gets its own git worktree that starts from `origin/main` (Claude Code branches worktrees from origin's default branch), not from whatever branch the folder has checked out; `--remote-spawn same-dir` runs them in the folder itself instead. Folders that aren't git repos always use same-dir. Chats started in the Claude desktop app show on the phone through its own "Connect new sessions to Remote Control" setting. Turning Lidocaine off leaves phone access running, so phone chats stay connected while the Mac is awake. A battery guard stops phone access when the Mac is on battery below 20% (set `LIDOCAINE_REMOTE_MIN_BATTERY` to change it), so it can never drain a forgotten laptop. If you use the Claude desktop app, also consider turning off its "Keep awake on battery power" setting.
- **Menu bar panel.** Click the icon for a small panel: an on/off switch with the time left on a ring (on battery it also says when the battery guard will put it to sleep), a "Stay awake for" picker that also changes a running session, +1 h, phone access in one or all of your recent Claude folders, battery and temperature with the limits that put the Mac to sleep, and two switches: sleep when Claude and Codex finish, and Open at Login. Everything else has a sensible default (the screen locks when the lid closes, updates install by themselves).

## Requirements

- macOS 13 or newer on a MacBook. Tested on Apple Silicon (macOS 26).
- Xcode Command Line Tools for the menu bar app (`xcode-select --install`).
- For phone access: the [Claude Code CLI](https://code.claude.com/docs) signed in with a claude.ai Pro, Max, Team or Enterprise plan.

## Install

```bash
git clone https://github.com/ArtemKorchunov/lidocaine.git ~/lidocaine
cd ~/lidocaine
./install.sh
```

That links the `lidocaine` command into `~/.local/bin` and builds the menu bar app into `~/Applications/Lidocaine.app`. Keep the cloned folder: the command points into it.

Options:

```bash
./install.sh --no-app     # only the command, no menu bar app
./install.sh --skill      # also install the Claude Code skill (see below)
```

### Optional: no password prompts

Changing sleep settings needs admin rights, so by default `on` and `off` ask for your password (Touch ID works in a terminal if you have enabled Touch ID for sudo). To switch without prompts:

```bash
lidocaine install-nopasswd
```

This adds `/etc/sudoers.d/lidocaine`, validated with `visudo`, that allows **only** the exact commands Lidocaine runs (`pmset -a disablesleep 0|1`, `pmset sleepnow`, `pmset -b|-c powermode 0|1|2`, `pmset -a powermode 1`, and `powermetrics --samplers thermal -n 1 -i 1000`). The script itself never gets passwordless root. Remove it with `lidocaine uninstall-nopasswd`.

The heal agent is a per-user LaunchAgent (`~/Library/LaunchAgents/com.oddproblems.lidocaine.heal.plist`). Manage it with `lidocaine heal-agent install|uninstall|status`. It treats any `disablesleep 1` without a running Lidocaine watchdog as left over, so if you also set that by hand, uninstall the agent.

### Update

```bash
lidocaine update           # get the latest release and rebuild the menu bar app if it changed
lidocaine update --check   # only say whether an update is waiting
```

Updates follow [releases](https://github.com/ArtemKorchunov/lidocaine/releases): work on `main` reaches you only once it is released. The menu bar app does this for you: it checks GitHub every few hours and installs a new release by itself while its panel is closed. On the command line, `lidocaine update` moves the folder you cloned to the latest release and rebuilds the menu bar app when the app's code changed. If Lidocaine is on, the running session keeps going as it was, and the update takes effect the next time you turn it on. If you installed before `update` existed, update once by hand: `cd ~/lidocaine && git pull && ./install.sh`.

### Personal settings

Settings that should survive updates go in `~/.config/lidocaine/config`, one `NAME=value` per line (read as plain values, never run). Supported: `LIDOCAINE_CLAUDE_BIN` (which `claude` to run for phone access), `LIDOCAINE_SCHEDULE_IGNORE` (scheduled tasks to leave alone), `LIDOCAINE_REMOTE_MAX`, `LIDOCAINE_REMOTE_MIN_BATTERY`.

### Uninstall

```bash
./uninstall.sh
```

## Usage

```bash
lidocaine on                                   # lid-closed mode, runs in the background
lidocaine on --hours 3 --low-power             # stop after 3 hours, run cooler
lidocaine on --remote ~/code/my-project        # plus Claude Code sessions from your phone
lidocaine on --remote all                      # phone access in all your recent Claude folders
lidocaine on --remote ~/code/my-project --remote-spawn same-dir   # phone chats in the folder itself, on its current branch
lidocaine off                                  # normal sleep back (phone access keeps running)
lidocaine off --all                            # also stop phone access
lidocaine set-hours 2                          # running session: stop 2 hours from now (0 = no limit)
lidocaine status                               # human-readable state, including when it stops
lidocaine allow-schedules                      # let Claude turn on phone access for scheduled-task runs
lidocaine toggle
```

Logs: `/tmp/lidocaine-watchdog.log` and `/tmp/lidocaine-remote.d/*.log` (one per phone folder); a folder that failed to start keeps its log in `~/Library/Logs/Lidocaine/`, and `lidocaine status` lists them.

## Using it with Claude Code

Two ways to let Claude drive it:

- **Skill:** `./install.sh --skill` installs `claude-skill/` as `~/.claude/skills/lidocaine`. Claude then picks it up from phrases like "keep my Mac awake with the lid closed", "turn lidocaine off", or "let me start Claude sessions from my phone".
- **Start plan:** [CLAUDE.md](CLAUDE.md) is a step-by-step plan Claude can follow to install, verify and use Lidocaine on a new machine. Open Claude Code in the cloned folder and ask it to "set up Lidocaine".

## Is running with the lid closed safe?

Short version: on a fan-cooled MacBook Pro on a hard surface or stand, yes, low risk. Apple supports lid-closed use in its own clamshell mode. Never run it closed in a bag or on a bed. Details and sources: [docs/closed-lid-safety.md](docs/closed-lid-safety.md).

## How it is built

```
scripts/lidocaine.sh      the command: on/off, watchdog, Remote Control, state for the app
menubar/main.swift       the menu bar app (AppKit + SwiftUI panel, no dependencies)
menubar/Icons.swift      menu bar and app icons
menubar/tools/main.swift renders the .icns and previews
menubar/build.sh         compiles and installs ~/Applications/Lidocaine.app
claude-skill/SKILL.md    Claude Code skill
CLAUDE.md                install and usage plan for Claude
```

The open eye's iris is the Claude spark. The repo does not ship the logo: `menubar/build.sh` cuts it out of the Claude desktop app installed on your Mac (`/Applications/Claude.app`) at build time. Without the Claude app, the build falls back to a hand-drawn spark.

`pmset -a disablesleep` is undocumented by Apple. It has worked for years, but a future macOS could change it.

## License

MIT for the code in this repo.

Claude and the Claude logo are trademarks of Anthropic. Lidocaine is an independent project, not made, endorsed or supported by Anthropic. The logo is not covered by the MIT license.

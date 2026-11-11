# cc-tmux

Remember which [Claude Code](https://claude.com/claude-code) session runs in every tmux pane, and bring all of them back with one command after the server reboots (or the tmux server dies).

```
cc-tmux save             scan all panes, record each claude session id   (called from the tmux status bar)
cc-tmux list [file]      show the snapshot taken before the last reboot
cc-tmux restore [file]   rebuild the tmux sessions/windows and run `claude --resume` in every pane
```

## Why

On a shared HPC login node, tmux is the only thing keeping long Claude Code sessions alive. When the node reboots, tmux is gone and so is the mapping "which conversation was running where". Claude Code keeps every conversation on disk and can `--resume <session-id>`, but you have to find the ids by hand. cc-tmux does the bookkeeping.

## How it works

- `save` runs every 15 s from the tmux status line (it prints nothing, so the status bar is unchanged). For every pane it walks the process tree (3 levels) looking for a `claude` process, reads that process's record in `~/.claude/sessions/<pid>.json` (session id, working directory, session name), and writes one snapshot per host and boot: `~/.cache/cc-tmux/<host>-<boot_id>.json`. A pid-reuse check (`procStart` vs `/proc/<pid>/stat`) avoids stale records. If no claude is running it does not overwrite the last snapshot.
- `restore` picks the newest snapshot from a *previous* boot of this host (the boot id is different), recreates each tmux session / window with its original name and working directory, splits windows that had several panes, and starts `claude --resume <session-id>; exec $SHELL` in each pane. Then `tmux attach`.

## Requirements

- Linux (`/proc`), Python 3.8+, tmux 3.x
- Claude Code CLI ≥ 2.1 (uses the `~/.claude/sessions/<pid>.json` files it writes for every running session)

## Install

```bash
git clone https://github.com/Jacksonha7/cc-tmux.git
cd cc-tmux
./install.sh
```

`install.sh` copies the script to `~/.local/bin/cc-tmux` and appends the status-line hook to `~/.tmux.conf` (it does nothing if the hook is already there). Then reload tmux:

```bash
tmux source-file ~/.tmux.conf      # or restart tmux
```

Manual install, if you prefer:

```bash
mkdir -p ~/.local/bin && cp cc-tmux ~/.local/bin/ && chmod +x ~/.local/bin/cc-tmux
cat >> ~/.tmux.conf <<'EOF'
# cc-tmux: snapshot the Claude Code session in every pane every 15 s
set -g status-interval 15
set -ag status-right '#(python3 ~/.local/bin/cc-tmux save)'
EOF
```

## Use

Nothing to do day to day — the status line keeps the snapshot fresh. After a reboot:

```bash
cc-tmux list        # see what was running before the reboot
cc-tmux restore     # rebuild everything, then: tmux attach
```

Each restored pane starts at the resume picker of that conversation; press Enter to continue it. Snapshots are small JSON files, one per boot, in `~/.cache/cc-tmux/`; delete old ones whenever you like.

## Limitations

- Only tracks `claude` processes that are direct descendants (≤ 3 levels) of the pane's shell.
- Panes without a claude session are not restored (only the claude ones are).
- Layout is restored as `tiled`, not the exact original geometry.
- Tested on tmux 3.4 / Claude Code 2.1.x on Linux. The session-file format is Claude Code's internal format and may change.

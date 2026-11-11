#!/usr/bin/env bash
# Install cc-tmux: copy the script to ~/.local/bin and add the tmux status-line hook.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bin="$HOME/.local/bin"
conf="$HOME/.tmux.conf"

mkdir -p "$bin"
install -m 755 "$here/cc-tmux" "$bin/cc-tmux"
echo "installed $bin/cc-tmux"

if grep -q 'cc-tmux save' "$conf" 2>/dev/null; then
  echo "tmux hook already present in $conf"
else
  cat >> "$conf" <<'EOF'

# cc-tmux: snapshot the Claude Code session in every pane every 15 s (prints nothing)
set -g status-interval 15
set -ag status-right '#(python3 ~/.local/bin/cc-tmux save)'
EOF
  echo "added status-line hook to $conf"
fi

case ":$PATH:" in
  *":$bin:"*) ;;
  *) echo "note: $bin is not on your PATH; add  export PATH=\"\$HOME/.local/bin:\$PATH\"  to your shell rc" ;;
esac
echo "reload tmux:  tmux source-file ~/.tmux.conf"

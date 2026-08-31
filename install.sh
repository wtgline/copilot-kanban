#!/usr/bin/env bash
#
# copilot-kanban installer (macOS)
#
# Symlinks the two commands into a bin directory on your PATH and installs the
# Copilot CLI hook configuration that lets the board detect when an agent is
# busy or finished.
#
# Safe to re-run. Never overwrites or deletes a hook file it did not create.
#
#   ./install.sh                  # install to ~/.local/bin
#   ./install.sh --prefix ~/bin   # install somewhere else
#   ./install.sh --uninstall      # remove what this script installed
#
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${HOME}/.local/bin"
COPILOT_HOME="${COPILOT_HOME:-${HOME}/.copilot}"
HOOKS_DIR="${COPILOT_HOME}/hooks"
HOOK_FILE="${HOOKS_DIR}/copilot-kanban.json"
# Written into the generated hook file so uninstall can prove it owns it.
HOOK_MARKER="generated-by-copilot-kanban-install"
UNINSTALL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --prefix)    PREFIX="${2:?--prefix needs a directory}"; shift 2 ;;
    --uninstall) UNINSTALL=1; shift ;;
    -h|--help)   sed -n '2,14p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           echo "unknown option: $1" >&2; exit 2 ;;
  esac
done

info() { printf '  %s\n' "$*"; }
ok()   { printf '  \033[32mok\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m  %s\n' "$*"; }
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

command -v python3 >/dev/null 2>&1 || die "python3 not found — install it and retry"

# Is $HOOK_FILE one we generated? Always checked before we delete it.
hook_is_ours() {
  [ -f "$HOOK_FILE" ] || return 1
  python3 - "$HOOK_FILE" "$HOOK_MARKER" <<'PY'
import json, sys
try:
    with open(sys.argv[1], encoding="utf-8") as f:
        data = json.load(f)
except Exception:
    sys.exit(1)
sys.exit(0 if data.get("_comment") == sys.argv[2] else 1)
PY
}

# ---------------------------------------------------------------- uninstall
if [ "$UNINSTALL" -eq 1 ]; then
  echo "Uninstalling copilot-kanban"
  for cmd in copilot-kanban copilot-hook; do
    target="${PREFIX}/${cmd}"
    if [ -L "$target" ]; then
      link_dest="$(readlink "$target" || true)"
      case "$link_dest" in
        "${REPO_DIR}/bin/"*) rm -f "$target"; ok "removed ${target}" ;;
        *) warn "${target} points elsewhere (${link_dest}) — leaving it alone" ;;
      esac
    elif [ -e "$target" ]; then
      warn "${target} is not a symlink — leaving it alone"
    fi
  done

  if [ ! -f "$HOOK_FILE" ]; then
    info "no hook file at ${HOOK_FILE}"
  elif hook_is_ours; then
    rm -f "$HOOK_FILE"; ok "removed ${HOOK_FILE}"
    # If we displaced someone else's file on install, put it back.
    newest_backup="$(ls -t "${HOOK_FILE}".bak.* 2>/dev/null | head -1 || true)"
    if [ -n "$newest_backup" ]; then
      mv "$newest_backup" "$HOOK_FILE"
      ok "restored previous hook config from $(basename "$newest_backup")"
    fi
  else
    warn "${HOOK_FILE} was not created by this installer — leaving it alone"
  fi

  echo
  info "Left untouched: your Copilot session data in ${COPILOT_HOME}, and the"
  info "board's own state (board-status.json, kanban-state.json)."
  info "Delete those by hand if you want a completely clean slate."
  exit 0
fi

# -------------------------------------------------------------- preflight
echo "Installing copilot-kanban"
echo

[ "$(uname -s)" = "Darwin" ] || die "this tool currently supports macOS only"

PYV="$(python3 -c 'import sys; print("%d.%d" % sys.version_info[:2])')"
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 8) else 1)' \
  || die "python 3.8 or newer is required (found ${PYV})"
ok "python3 ${PYV}"

if command -v tmux >/dev/null 2>&1; then
  ok "tmux $(tmux -V | awk '{print $2}')"
else
  warn "tmux not found — install it (brew install tmux) or the board cannot"
  warn "link sessions to panes or dispatch agents"
fi

if command -v copilot >/dev/null 2>&1; then
  ok "github copilot cli"
else
  warn "copilot not found on PATH — install GitHub Copilot CLI:"
  warn "https://docs.github.com/copilot/how-tos/use-copilot-agents/use-copilot-cli"
fi

# ------------------------------------------------------------------ install
mkdir -p "$PREFIX"
for cmd in copilot-kanban copilot-hook; do
  src="${REPO_DIR}/bin/${cmd}"
  [ -f "$src" ] || die "missing ${src} — is the repo complete?"
  chmod +x "$src"
  target="${PREFIX}/${cmd}"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    die "${target} exists and is not a symlink; move it aside and retry"
  fi
  ln -sfn "$src" "$target"
  ok "linked ${target}"
done

mkdir -p "$HOOKS_DIR"
if [ -f "$HOOK_FILE" ] && ! hook_is_ours; then
  backup="${HOOK_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$HOOK_FILE" "$backup"
  warn "an unrelated ${HOOK_FILE} was already there"
  info "backed it up to ${backup} (restored if you --uninstall)"
fi

# Build the JSON in Python so the hook path is correctly quoted for the shell
# and correctly escaped for JSON, even when it contains spaces.
python3 - "$HOOK_FILE" "${PREFIX}/copilot-hook" "$HOOK_MARKER" <<'PY'
import json, shlex, sys

out_path, hook_path, marker = sys.argv[1], sys.argv[2], sys.argv[3]
quoted = shlex.quote(hook_path)


def entry(event):
    return [{"type": "command", "bash": "%s %s" % (quoted, event), "timeoutSec": 5}]


config = {
    "version": 1,
    "_comment": marker,
    "hooks": {
        "sessionStart": entry("start"),
        "userPromptSubmitted": entry("prompt"),
        "agentStop": entry("stop"),
    },
}
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2)
    f.write("\n")
PY
python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$HOOK_FILE" \
  || die "generated hook config is not valid JSON: ${HOOK_FILE}"
ok "installed ${HOOK_FILE}"

# --------------------------------------------------------------- next steps
echo
case ":${PATH}:" in
  *":${PREFIX}:"*) ;;
  *)
    warn "${PREFIX} is not on your PATH. Add this to your shell profile:"
    echo
    echo "      export PATH=\"${PREFIX}:\$PATH\""
    echo
    ;;
esac

cat <<'EOF'
Done.

  1. Restart any Copilot CLI sessions you already have open.
     Hooks are read once at startup, so existing sessions won't report
     their status until they are restarted.

  2. Start the board:

        copilot-kanban

     It serves on http://127.0.0.1:47900 and opens your browser.

EOF

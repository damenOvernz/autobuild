#!/usr/bin/env bash
# Shared settings and helpers for AutoBuild scripts.
AB_HOME="${AB_HOME:-$HOME/autobuild}"
# shellcheck source=/dev/null
[ -f "$AB_HOME/config.env" ] && source "$AB_HOME/config.env"
AB_PROJECTS="${AB_PROJECTS:-$HOME/autobuild-projects}"
AB_REMOTE="${AB_REMOTE:-gdrive:AutoBuild}"
AB_NTFY_SERVER="${AB_NTFY_SERVER:-https://ntfy.sh}"
AB_MAX_ROUNDS="${AB_MAX_ROUNDS:-12}"
AB_MAX_TURNS="${AB_MAX_TURNS:-200}"
AB_MAX_GPT_QUESTIONS="${AB_MAX_GPT_QUESTIONS:-25}"
AB_GPT_TIMEOUT="${AB_GPT_TIMEOUT:-600}"
AB_AUTO_NEXT="${AB_AUTO_NEXT:-1}"      # 1 = GPT reviews each finished phase and starts the next one
AB_MAX_PHASES="${AB_MAX_PHASES:-3}"    # automatic phases per plan before stopping for Damen
AB_IN="${AB_IN:-/srv/autobuild-in}"     # read-only copies of your server projects (made by "autobuild share")
AB_OUT="${AB_OUT:-/srv/autobuild-out}"   # finished work you can pull back ("autobuild bring")
[ -n "${AB_PATH:-}" ] && export PATH="$AB_PATH:$PATH"
export PATH="$AB_HOME/bin:$PATH"
[ -n "${DOCKER_HOST:-}" ] && export DOCKER_HOST     # AutoBuild's private (rootless) Docker, if set up

ab_docker_cleanup() { # remove every test container/network/volume the build left behind (private Docker only)
  [ "${AB_DOCKER:-0}" = "1" ] && [ -n "${DOCKER_HOST:-}" ] || return 0
  docker ps -aq 2>/dev/null | xargs -r docker rm -f >/dev/null 2>&1
  docker network prune -f >/dev/null 2>&1; docker volume prune -af >/dev/null 2>&1
  return 0
}

ab_log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }

ab_notify() { # ab_notify "Title" "message" [priority]
  [ -z "${AB_NTFY_TOPIC:-}" ] && return 0
  curl -fsS -m 20 -H "Title: $1" -H "Priority: ${3:-default}" \
    -d "$2" "$AB_NTFY_SERVER/$AB_NTFY_TOPIC" >/dev/null 2>&1 || true
}

ab_slug() { # turn "My Cool App.md" into "my-cool-app"
  local s="${1%.md}"
  s=$(printf '%s' "$s" | tr '[:upper:]' '[:lower:]' | sed -e 's/[^a-z0-9]\+/-/g' -e 's/^-//' -e 's/-$//')
  printf '%s' "${s:-project}"
}

ab_state() { cat "$AB_PROJECTS/$1/.autobuild/state" 2>/dev/null || echo none; }
ab_set_state() { echo "$2" > "$AB_PROJECTS/$1/.autobuild/state"; }

ab_any_running() {
  local d pid
  for d in "$AB_PROJECTS"/*/; do
    [ -f "$d.autobuild/state" ] || continue
    [ "$(cat "$d.autobuild/state")" = "running" ] || continue
    pid=$(cat "$d.autobuild/pid" 2>/dev/null || true)
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then return 0; fi
    echo "crashed" > "$d.autobuild/state"   # process died without finishing
  done
  return 1
}

# Copy the human-readable files (status, decisions, report...) up to Drive
ab_sync_out() {
  local slug="$1" m="$AB_PROJECTS/$1/.autobuild"
  # Newest-first live activity, readable on the watch page
  if [ -f "$m/activity.log" ]; then
    { echo "Updated $(date '+%Y-%m-%d %H:%M:%S')"; tail -n 80 "$m/activity.log" | tac; } > "$m/activity.md"
  fi
  rclone copy "$AB_PROJECTS/$slug/.autobuild" "$AB_REMOTE/projects/$slug" \
    --include "*.md" --include "state" >/dev/null 2>&1 || true
  # Remove an old question from Drive once it's been answered
  [ -f "$AB_PROJECTS/$slug/.autobuild/NEEDS_DAMEN.md" ] || \
    rclone deletefile "$AB_REMOTE/projects/$slug/NEEDS_DAMEN.md" >/dev/null 2>&1 || true
}

#!/usr/bin/env bash
# Reproducible demo for recording with asciinema.
#
#   asciinema rec -c "bash demo.sh" demo.cast
#
# It runs in an isolated $HOME with throwaway sample kubeconfigs, so your real
# ~/.kube/config is never touched. Tune the pace with TYPE_SPEED / STEP_PAUSE.
# shellcheck shell=bash

set -u

TYPE_SPEED="${TYPE_SPEED:-0.045}"   # delay between typed characters
STEP_PAUSE="${STEP_PAUSE:-1.1}"     # pause after each command's output
PROMPT_USER="${PROMPT_USER:-you@laptop}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SANDBOX="$(mktemp -d)"
export HOME="$SANDBOX"
trap 'rm -rf "$SANDBOX"' EXIT
mkdir -p "$HOME/.kube"

# Create a few sample kubeconfigs. File names become the context names, and one
# is called "prod" to show the red production highlight.
for ctx in acme-dev acme-staging acme-prod; do
  cat > "$HOME/.kube/${ctx}.yaml" <<YAML
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://${ctx}.example.com
  name: placeholder
contexts:
- context:
    cluster: placeholder
    user: placeholder
  name: placeholder
users:
- name: placeholder
  user:
    token: fake-token
current-context: placeholder
YAML
done

# shellcheck source=/dev/null
source "$SCRIPT_DIR/kc.sh"

# `kc` is an alias; enable alias expansion so it works inside this script.
shopt -s expand_aliases

# A prompt that mirrors kc's own prompt integration: appends the current
# context, yellow normally and red for production.
demo_prompt() {
  local ctx color reset=$'\033[00m'
  ctx="$(kc_check 2>/dev/null || true)"
  printf '\033[01;32m%s\033[00m:\033[01;34m~\033[00m' "$PROMPT_USER"
  if [ -n "$ctx" ]; then
    color=$'\033[01;33m'
    case "$ctx" in *prod*) color=$'\033[01;31m';; esac
    printf ' %s(%s)%s' "$color" "$ctx" "$reset"
  fi
  printf '$ '
}

type_cmd() {
  local cmd="$1" i
  for (( i = 0; i < ${#cmd}; i++ )); do
    printf '%s' "${cmd:i:1}"
    sleep "$TYPE_SPEED"
  done
  printf '\n'
}

run() {
  demo_prompt
  type_cmd "$1"
  eval "$1"
  echo
  sleep "$STEP_PAUSE"
}

sleep 0.6
run "ls ~/.kube"
run "kc -g"
run "kc -l"
run "kc -u 1"
run "kc -n backend"
run "kc -u 2"
run "kc -l"
demo_prompt
sleep 1.5
echo

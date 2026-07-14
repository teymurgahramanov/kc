#!/usr/bin/env bash
# kc — Simplifies Kubernetes cluster management.
# This script is meant to be sourced from your shell rc file (bash or zsh).
# shellcheck shell=bash

KC_VERSION="1.4.0"

kc_help () {
  cat << EOF
kc — Simplifies Kubernetes clusters management. (v${KC_VERSION})
Usage: kc OPTION ARGUMENT
Options:
  -g
    Generate new ~/.kube/config file from kubeconfig files located under ~/.kube/
  -l
    Get list of contexts
  -u NUMBER
    Use context
  -d NUMBER
    Delete context
  -n STRING
    Set default namespace for the current context
  -s NAME [NAMESPACE]
    Generate a kubeconfig for a service account into
    ~/.kube/, based on the current context. NAMESPACE defaults to "default".
  -v
    Print version
  -h
    Get help
EOF
}

# Print an error message to stderr.
kc_handler() {
  printf '\033[0;31mError: %s\033[0m\n' "$1" >&2
  printf 'Type kc -h for help.\n' >&2
}

# Echo the current kubectl context, or return non-zero if unavailable.
kc_check () {
  command -v kubectl >/dev/null 2>&1 || return 1
  local ctx
  ctx="$(kubectl config current-context 2>/dev/null)" || return 1
  [ -n "$ctx" ] || return 1
  printf '%s' "$ctx"
}

# Run `sed -i` portably across GNU (Linux) and BSD (macOS) sed.
kc_sed_inplace() {
  if sed --version >/dev/null 2>&1; then
    sed -i -E "$@"
  else
    sed -i '' -E "$@"
  fi
}

# Base64-decode stdin portably (GNU uses --decode, BSD/macOS uses -D).
kc_base64_decode() {
  if printf '' | base64 --decode >/dev/null 2>&1; then
    base64 --decode
  else
    base64 -D
  fi
}

# Sanitize context/cluster/user names in a kubeconfig file so that they match
# the file name. Echoes the file path back on success.
kc_sanitize() {
  local file="$1" name script
  if ! command -v sed >/dev/null 2>&1; then
    kc_handler "sed command not found."
    return 1
  fi
  name="$(basename "$file" | sed -E 's/\.(ya?ml)$//' | sed 's/[^a-zA-Z0-9]/-/g')"
  script="
    s/^([[:space:]]*(-[[:space:]]*)?name:[[:space:]]+).+/\1$name/;
    s/^([[:space:]]*(-[[:space:]]*)?cluster:[[:space:]]+).+/\1$name/;
    s/^([[:space:]]*(-[[:space:]]*)?user:[[:space:]]+).+/\1$name/;
    s/^([[:space:]]*current-context:[[:space:]]+).+/\1$name/;
  "
  kc_sed_inplace "$script" "$file"
  printf '%s' "$file"
}

kc_context () {
  local action="${1:-}" arg="${2:-}" extra="${3:-}"

  case "$action" in
    g)
      local temp_dir="$HOME/.kc_tmp"
      local config_files sanitized_files="" file

      if ! mkdir -p "$temp_dir" 2>/dev/null; then
        kc_handler "Failed to create temporary directory."
        return 1
      fi

      config_files="$(find "$HOME/.kube" -maxdepth 1 -type f ! -name config ! -name config_tmp)"

      while IFS= read -r file; do
        [ -z "$file" ] && continue
        if ! kubectl --kubeconfig="$file" config view >/dev/null 2>&1; then
          kc_handler "Invalid kubeconfig file: $file"
          rm -rf "$temp_dir"
          return 1
        fi
        cp "$file" "$temp_dir"/
        sanitized_files="$sanitized_files:$(kc_sanitize "$temp_dir/$(basename "$file")")"
      done <<EOF
$config_files
EOF

      sanitized_files="${sanitized_files#:}"

      if [ -z "$sanitized_files" ]; then
        kc_handler "No kubeconfig files found under ~/.kube/."
        rm -rf "$temp_dir"
        return 1
      fi

      # Merge sanitized files into a single flattened config.
      if KUBECONFIG="$sanitized_files" kubectl config view --merge --flatten > "$HOME/.kube/config_tmp" \
        && mv "$HOME/.kube/config_tmp" "$HOME/.kube/config"; then
        export KUBECONFIG="$HOME/.kube/config"
        echo "Kubeconfig has been generated from:"
        printf '%s\n' "$config_files" | sed '/^$/d' | sort | sed "s|^$HOME/|~/|"
      else
        kc_handler "Failed to generate kubeconfig."
        rm -f "$HOME/.kube/config_tmp"
        rm -rf "$temp_dir"
        return 1
      fi

      rm -rf "$temp_dir"
      ;;
    l)
      kubectl config get-contexts | awk '
        NR == 1 {
          cl = index($0, "CLUSTER")
          ns = index($0, "NAMESPACE")
          print "N " substr($0, 1, cl - 1) substr($0, ns)
          next
        }
        { line = substr($0, 1, cl - 1) substr($0, ns) }
        /\*/ { printf "\033[0;36m%d %s\033[0m\n", NR - 1, line; next }
             { print (NR - 1) " " line }
      '
      ;;
    u|d)
      local names count index name
      if ! [[ "$arg" =~ ^[0-9]+$ ]]; then
        kc_handler "Provide a valid context number."
        return 1
      fi
      names="$(kubectl config get-contexts -o name)"
      count="$(printf '%s\n' "$names" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
      index="$arg"
      if [ "$index" -lt 1 ] || [ "$index" -gt "$count" ]; then
        kc_handler "Wrong index."
        return 1
      fi
      name="$(printf '%s\n' "$names" | sed -n "${index}p")"
      if [ -z "$name" ]; then
        kc_handler "Wrong index."
        return 1
      fi
      if [ "$action" = "u" ]; then
        kubectl config use-context "$name"
      else
        kubectl config delete-context "$name"
      fi
      ;;
    n)
      if [ -z "$arg" ]; then
        kc_handler "Provide a namespace."
        return 1
      fi
      kubectl config set-context --current --namespace="$arg"
      ;;
    s)
      local sa_name="$arg" sa_namespace token cluster ca server ctx_name outfile
      sa_namespace="${extra:-default}"

      if [ -z "$sa_name" ]; then
        kc_handler "Provide a service account secret name."
        return 1
      fi

      token="$(kubectl -n "$sa_namespace" get secret "$sa_name" \
        -o jsonpath='{.data.token}' 2>/dev/null | kc_base64_decode 2>/dev/null)"
      if [ -z "$token" ]; then
        kc_handler "Could not read a token from secret \"$sa_name\" in namespace \"$sa_namespace\"."
        return 1
      fi

      cluster="$(kubectl config view --minify -o jsonpath='{.clusters[].name}' 2>/dev/null)"
      server="$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}' 2>/dev/null)"
      ca="$(kubectl -n "$sa_namespace" get secret "$sa_name" -o jsonpath='{.data.ca\.crt}' 2>/dev/null)"
      if [ -z "$cluster" ] || [ -z "$server" ]; then
        kc_handler "Could not determine the current cluster. Select a context first."
        return 1
      fi

      ctx_name="${cluster}-${sa_name}-${sa_namespace}"
      outfile="$HOME/.kube/kubeconfig-${ctx_name}.yaml"
      mkdir -p "$HOME/.kube" 2>/dev/null

      cat > "$outfile" <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $ca
    server: $server
  name: $cluster
current-context: $ctx_name
contexts:
- name: $ctx_name
  context:
    cluster: $cluster
    namespace: $sa_namespace
    user: $sa_name
users:
- name: $sa_name
  user:
    token: $token
EOF

      echo "Generated kubeconfig for service account \"$sa_name\" (namespace \"$sa_namespace\"):"
      printf '%s\n' "$outfile" | sed "s|^$HOME/|~/|"
      echo "Run 'kc -g' to merge it into ~/.kube/config."
      ;;
  esac
}

kc_main () {
  if [ $# -eq 0 ]; then
    kc_handler "Provide an option."
    return 1
  fi

  case "$1" in
    -g)
      kc_context g && { echo ""; kc_context l; }
      ;;
    -l)
      kc_context l
      ;;
    -u)
      kc_context u "${2:-}"
      ;;
    -d)
      kc_context d "${2:-}"
      ;;
    -n)
      kc_context n "${2:-}"
      ;;
    -s)
      kc_context s "${2:-}" "${3:-}"
      ;;
    -v)
      echo "kc v${KC_VERSION}"
      ;;
    -h)
      kc_help
      ;;
    *)
      kc_handler "Wrong option."
      return 1
      ;;
  esac
}

# Append the current kubectl context to the shell prompt.
kc_ps1() {
  local kube_context color reset
  kube_context="$(kc_check)" || return 0
  [ -n "$kube_context" ] || return 0

  if [ -n "${ZSH_VERSION:-}" ]; then
    color=$'%{\033[01;33m%}'
    case "$kube_context" in *prod*) color=$'%{\033[01;31m%}';; esac
    reset=$'%{\033[00m%}'
    [ -z "${KC_ORIG_PROMPT+x}" ] && KC_ORIG_PROMPT="$PROMPT"
    PROMPT="${KC_ORIG_PROMPT}${color}(${kube_context})${reset} "
  else
    color='\[\033[01;33m\]'
    case "$kube_context" in *prod*) color='\[\033[01;31m\]';; esac
    reset='\[\033[00m\]'
    [ -z "${KC_ORIG_PS1+x}" ] && KC_ORIG_PS1="$PS1"
    PS1="${KC_ORIG_PS1}${color}(${kube_context})${reset} "
  fi
}

alias kc=kc_main

# Register the prompt hook for the running shell.
if [ -n "${ZSH_VERSION:-}" ]; then
  autoload -Uz add-zsh-hook 2>/dev/null
  if command -v add-zsh-hook >/dev/null 2>&1; then
    add-zsh-hook precmd kc_ps1
  else
    # shellcheck disable=SC2206,SC2154
    precmd_functions+=(kc_ps1)
  fi
else
  case "${PROMPT_COMMAND:-}" in
    *kc_ps1*) ;;
    *) PROMPT_COMMAND="kc_ps1${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
  esac
fi

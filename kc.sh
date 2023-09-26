kc_help () {
  echo "kc — is a set of aliases to ease the management of kube config contexts"
  echo ""
  echo "kcg     Generate new ~./kube/config file from context files located under ~./kube/"
  echo "kcgc    Get numbered list of contexts"
  echo "kcuc    Switch to context by providing its number: kcuc N"
}

kc_context () {
  KUBE_CONTEXT_NAMES=$(kubectl config get-contexts -o name)
  KUBE_CONTEXT_FULL=$(kubectl config get-contexts)

  IFS=$'\n' read -rd '' -a KUBE_CONTEXT_NAMES_ARRAY <<< "$KUBE_CONTEXT_NAMES"
  IFS=$'\n' read -rd '' -a KUBE_CONTEXT_FULL_ARRAY <<< "$KUBE_CONTEXT_FULL"

  if [ $# -eq 0 ]; then
    COUNTER=0
    for line in "${KUBE_CONTEXT_FULL_ARRAY[@]}"; do
      if [ $COUNTER == 0 ]; then
        echo "N $line"
        ((COUNTER++))
      else
        echo "$COUNTER $line"
        ((COUNTER++))
      fi
    done
  fi

  if [ $# -eq 1 ]; then
    ARG=$1
    if [[ "$ARG" =~ ^[0-9]+$ ]]; then
      INDEX=$((ARG - 1))
      if [ "$INDEX" -ge 0 ] && [ "$INDEX" -lt "${#KUBE_CONTEXT_NAMES_ARRAY[@]}" ]; then
        kubectl config use-context "${KUBE_CONTEXT_NAMES_ARRAY[$INDEX]}"
      else
        echo "Invalid index"
      fi
    else
      echo "Argument is not a valid number"
    fi
  fi
}

kc_generate () {
  export KUBECONFIG=~/.kube/config:$(find ~/.kube -maxdepth 1 -type f ! -name config | tr '\n' ':' ) &&\
  kubectl config view --flatten > ~/.kube/config_tmp && \
  mv ~/.kube/config_tmp ~/.kube/config && \
  echo -e '\e[93mKubeconfig has been generated from:\e[0m' && \
  echo $KUBECONFIG | tr ':' '\n' | sed '/^$/d' | sort && \
  echo && \
  kc_context
}

kube_ps1() {
  local KUBE_CONTEXT
  if command -v kubectl &>/dev/null; then
    KUBE_CONTEXT="$(kubectl config current-context 2>/dev/null)"
    alias k='kubectl'
    alias kch=kc_help
    alias kcgc=kc_context
    alias kcuc=kc_context # Provide context number
    alias kcg=kc_generate
  else
    KUBE_CONTEXT=""
  fi
  if [ -n "$KUBE_CONTEXT" ]; then
    if [[ $KUBE_CONTEXT =~ prod|production ]]; then
      PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]\[\033[01;31m\]($KUBE_CONTEXT)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
    else
      PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]\[\033[01;33m\]($KUBE_CONTEXT)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
    fi
  else
    PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
  fi
}

PROMPT_COMMAND=kube_ps1

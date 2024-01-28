#!/bin/bash

kc_help () {
  cat << EOF
kc — Simplifies the management of Kubernetes configuration contexts.
Usage: kc OPTION ARGUMENT
Options:
  -g
    Generate new ~./kube/config file from context files located under ~./kube/
  -l
    Get numbered list of contexts
  -u NUMBER
    Use context
  -d NUMBER
    Delete context
  -r NUMBER STRING
    Rename context
  -m --KEY=VALUE ... --KEY=VALUE
    Modify current context's fields. Refer: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_config/kubectl_config_set-context/.
  -h
    Help
EOF
}

kc_check () {
  if command -v kubectl &>/dev/null; then
    echo "$(kubectl config current-context 2>/dev/null)"
  else
    return 1
  fi
}

kc_handler() {
  ERR_COLOR='\033[0;31m'
  NO_COLOR='\033[0m'
  echo -e "${ERR_COLOR}Error: $1 ${NO_COLOR}"
  echo "Type kc -h for help."
}

kc_context () {
  KUBE_CONTEXT_NAMES=$(kubectl config get-contexts -o name)
  KUBE_CONTEXT_FULL=$(kubectl config get-contexts)

  IFS=$'\n' read -rd '' -a KUBE_CONTEXT_NAMES_ARRAY <<< "$KUBE_CONTEXT_NAMES"
  IFS=$'\n' read -rd '' -a KUBE_CONTEXT_FULL_ARRAY <<< "$KUBE_CONTEXT_FULL"

  if [[ "$2" =~ ^[0-9]+$ ]]; then
    INDEX=$(($2 - 1))
    if ! [ "$INDEX" -ge 0 ] && ! [ "$INDEX" -lt "${#KUBE_CONTEXT_NAMES_ARRAY[@]}" ]; then
      return 1
    fi
  fi

  case $1 in
    u)
      kubectl config use-context "${KUBE_CONTEXT_NAMES_ARRAY[$INDEX]}"
      ;;
    d)
      kubectl config delete-context "${KUBE_CONTEXT_NAMES_ARRAY[$INDEX]}"
      ;;
    r)
      kubectl config rename-context "${KUBE_CONTEXT_NAMES_ARRAY[$INDEX]}" "$3"
      ;;
    m)
      kubectl config set-context --current "${@:2}"
      ;;
    l)
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
      ;;
    *)
      return 1
      ;;
  esac
}

kc_generate () {
  export KUBECONFIG=~/.kube/config:$(find ~/.kube -maxdepth 1 -type f ! -name config ! -name config_tmp | tr '\n' ':' ) &&\
  kubectl config view --merge --flatten > ~/.kube/config_tmp && \
  mv ~/.kube/config_tmp ~/.kube/config && \
  echo "Kubeconfig has been generated from:" && \
  echo $KUBECONFIG | tr ':' '\n' | sed '/^$/d' | sort
}

kc_main () {
  if [ $# -eq 0 ]; then
    kc_handler "Provide an option."
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -g)
        kc_generate
        echo ""
        kc_context l
        shift $#
        ;;
      -l)
        kc_context l
        shift $#
        ;;
      -u)
        kc_context u $2
        shift $#
        ;;
      -d)
        kc_context d $2
        shift $#
        ;;
      -r)
        kc_context r $2 $3
        shift $#
        ;;
      -m)
        kc_context m "${@:2}"
        shift $#
        ;;
      -h)
        kc_help
        shift $#
        ;;
      *)
        kc_handler "Wrong option."
        shift $#
        ;;
    esac
  done
}

kc_ps1() {
  local KUBE_CONTEXT
  KUBE_CONTEXT="$(kc_check)"
  if [[ $? -eq 0 ]]; then
    alias kc=kc_main
    if [[ $KUBE_CONTEXT =~ prod ]]; then
      PS1="\[\033[01;32m\]\u@\h\[\033[00m\]\[\033[01;31m\]($KUBE_CONTEXT)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
    else
      PS1="\[\033[01;32m\]\u@\h\[\033[00m\]\[\033[01;33m\]($KUBE_CONTEXT)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
    fi
  else
    PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
  fi
}

PROMPT_COMMAND=kc_ps1
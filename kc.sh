#!/bin/bash

kc_help () {
  echo "Easy management of kubectl config contexts"
  echo "Usage: kc OPTION"
  echo "Options:"
  echo "-g"
  echo "  Generate new ~./kube/config file from context files located under ~./kube/"
  echo "-l"
  echo "  Get numbered list of contexts"
  echo "-u NUMBER"
  echo "  Switch to context"
  echo "-h"
  echo "  Help"
}

kc_check () {
  if command -v kubectl &>/dev/null; then
    echo "$(kubectl config current-context 2>/dev/null)"
  else
    return 1
  fi
}

kc_handler() {
  echo "Error: $1"
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
        return 1
      fi
    else
      return 1
    fi
  fi
}

kc_generate () {
  export KUBECONFIG=~/.kube/config:$(find ~/.kube -maxdepth 1 -type f ! -name config ! -name config_tmp | tr '\n' ':' ) &&\
  kubectl config view --flatten > ~/.kube/config_tmp && \
  mv ~/.kube/config_tmp ~/.kube/config && \
  echo "Kubeconfig has been generated from:" && \
  echo $KUBECONFIG | tr ':' '\n' | sed '/^$/d' | sort
}

kc_main () {
  if [ $# -eq 0 ]; then
    kc_handler "Provide an option"
  fi
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -g)
        kc_generate
        echo ""
        kc_context
        shift
        ;;
      -l)
        kc_context
        shift
        ;;
      -u)
        if [[ $# -eq 2 ]]; then
          kc_context $2
          if [[ $? -eq 1 ]]; then
            kc_handler "Invalid context number"
            echo ""
            kc_help
          fi
          shift 2
        else
          kc_handler "-u option requires numeric argument"
          echo ""
          kc_help
          shift
        fi
        ;;
      -h)
        kc_help
        shift
        ;;
      *)
        kc_handler "Wrong option"
        echo ""
        kc_help
        shift
        ;;
    esac
  done
}

kc_ps1() {
  local KUBE_CONTEXT
  KUBE_CONTEXT="$(kc_check)"
  if [[ $? -eq 0 ]]; then
    alias kc=kc_main
    if [[ $KUBE_CONTEXT =~ prod|production ]]; then
      PS1="\[\033[01;32m\]\u@\h\[\033[00m\]\[\033[01;31m\]($KUBE_CONTEXT)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
    else
      PS1="\[\033[01;32m\]\u@\h\[\033[00m\]\[\033[01;33m\]($KUBE_CONTEXT)\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
    fi
  else
    PS1="\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
  fi
}

PROMPT_COMMAND=kc_ps1

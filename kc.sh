#!/bin/bash

kc_help () {
  cat << EOF
kc — Simplifies Kubernetes clusters management.
Usage: kc OPTION ARGUMENT
Options:
  -g
    Generate new ~./kube/config file from kubeconfig files located under ~./kube/
  -l
    Get list of contexts
  -u NUMBER
    Use context
  -d NUMBER
    Delete context
  -n STRING
    Set default namespace for the current context
  -h
    Get help
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
    if [ "$INDEX" -ge 0 ] && ! [ "$INDEX" -lt "${#KUBE_CONTEXT_NAMES_ARRAY[@]}" ]; then
      kc_handler "Wrong index."
      return 1
    fi
  fi

  case $1 in
    g)

      TEMP_DIR=~/.kc_tmp
      mkdir -p $TEMP_DIR 2>/dev/null
      if [ $? -ne 0 ]; then
        kc_handler "Failed to create temporary directory."
        return 1
      fi

      CONFIG_FILES=$(find ~/.kube -maxdepth 1 -type f ! -name config ! -name config_tmp)
      SANITIZED_FILES=""

      for file in $CONFIG_FILES; do
        kubectl --kubeconfig=$file config view > /dev/null 2>&1
        if [ $? -ne 0 ]; then
          kc_handler "Invalid kubeconfig file: $file"
          return 1
        fi
        cp $file $TEMP_DIR
        SANITIZED_FILES="$SANITIZED_FILES:$(kc_sanitize $TEMP_DIR/$(basename $file))"
      done

      SANITIZED_FILES=${SANITIZED_FILES#:}

      # Merge sanitized files
      export KUBECONFIG=$SANITIZED_FILES
      kubectl config view --merge --flatten > ~/.kube/config_tmp && \
      mv ~/.kube/config_tmp ~/.kube/config && \
      export KUBECONFIG=~/.kube/config
      echo "Kubeconfig has been generated from:" && \
      echo $CONFIG_FILES | tr ' ' '\n' | sed '/^$/d' | sort

      rm -rf "$TEMP_DIR"
      ;;
    l)
      COUNTER=0
      for line in "${KUBE_CONTEXT_FULL_ARRAY[@]}"; do
        if [ $COUNTER == 0 ]; then
          echo "N $line"
          ((COUNTER++))
        elif [[ "$line" == *'*'* ]]; then
          HIGHLIGHT_COLOR='\033[0;36m'
          NO_COLOR='\033[0m'
          echo -e "${HIGHLIGHT_COLOR}$COUNTER ${line}${NO_COLOR}"
          ((COUNTER++))
        else
          echo "$COUNTER $line"
          ((COUNTER++))
        fi
      done
      ;;
    u)
      kubectl config use-context "${KUBE_CONTEXT_NAMES_ARRAY[$INDEX]}"
      ;;
    d)
      kubectl config delete-context "${KUBE_CONTEXT_NAMES_ARRAY[$INDEX]}"
      ;;
    n)
      kubectl config set-context --current --namespace="$2"
      ;;
  esac
}

kc_sanitize() {
  FILENAME=$(basename "$1" | sed 's/\(.yaml\|.yml\)$//' | sed 's/[^a-zA-Z0-9]/-/g')

  if ! command -v sed &>/dev/null; then
    kc_handler "sed command not found."
    return 1
  fi

  sed -i -E '
    s/^([[:space:]]*(-[[:space:]]*)?name:[[:space:]]+).+/\1'"$FILENAME"'/;
    s/^([[:space:]]*(-[[:space:]]*)?cluster:[[:space:]]+).+/\1'"$FILENAME"'/;
    s/^([[:space:]]*(-[[:space:]]*)?user:[[:space:]]+).+/\1'"$FILENAME"'/;
    s/^([[:space:]]*current-context:[[:space:]]+).+/\1'"$FILENAME"'/;
  ' "$1"

  echo $1
}

kc_main () {
  if [ $# -eq 0 ]; then
    kc_handler "Provide an option."
  fi

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -g)
        kc_context g
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
      -n)
        kc_context n $2
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
    local COLOR="\[\033[01;33m\]"  # default: yellow
    [[ $KUBE_CONTEXT =~ prod ]] && COLOR="\[\033[01;31m\]"  # red if prod
    CLEAN_PS1="${PS1/(*)/}"
    CLEAN_PS1="${CLEAN_PS1%" "}"
    PS1="${CLEAN_PS1}${COLOR}(${KUBE_CONTEXT})\[\033[00m\] "
  fi
}

PROMPT_COMMAND=kc_ps1

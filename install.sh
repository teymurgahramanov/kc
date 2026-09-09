#!/usr/bin/env bash
set -euo pipefail

VERSION="${KC_VERSION:-1.5.0}"
URL="https://raw.githubusercontent.com/teymurgahramanov/kc/v${VERSION}/kc.sh"
TARGET="${HOME}/.kc.sh"

if [ -n "${ZSH_VERSION:-}" ] || [ "$(basename "${SHELL:-}")" = "zsh" ]; then
  RC="${HOME}/.zshrc"
else
  RC="${HOME}/.bashrc"
fi

echo "Downloading kc v${VERSION} -> ${TARGET}"
curl -fsSL -o "${TARGET}" "${URL}"

touch "${RC}"
if sed --version >/dev/null 2>&1; then
  # GNU sed (Linux)
  sed -i '/source ~\/\.kc\.sh/d' "${RC}"
else
  # BSD sed (macOS)
  sed -i '' '/source ~\/\.kc\.sh/d' "${RC}"
fi
echo "source ~/.kc.sh" >> "${RC}"

echo "Added 'source ~/.kc.sh' to ${RC}"

# shellcheck disable=SC1090
source "${TARGET}"
echo "kc installed. Try: kc -h"

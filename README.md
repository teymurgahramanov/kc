# kc

Juggling a dozen Kubernetes clusters from the terminal?

**kc** is a tiny, pure-Bash `kubectl` context manager that makes switching, adding, and editing contexts simple. No more `kubectl config` commands.

<p align="center">
    <img src="demo.svg" style="width: 90%; height: auto;" />
</p>

## Features

🔢 Switch between contexts with `kc -u <context number>`.

🧩 Merge all your kubeconfig files into one with `kc -g`.

⭕ Set the default namespace for the current context with `kc -n <namespace>`.

⚠️ Always know which cluster you're in, thanks to the dynamic shell prompt.

🚨 Avoid costly mistakes: production clusters are automatically highlighted in __red__.

🤖 Generate a kubeconfig for a service account with `kc -s <sa-name>`.

⭐️ Single file and dependency-free.

## Install

### bash

```bash
curl -o ~/.kc.sh -L https://raw.githubusercontent.com/teymurgahramanov/kc/v1.4.0/kc.sh && \
  sed -i '/source ~\/\.kc\.sh/d' ~/.bashrc && \
  echo "source ~/.kc.sh" >> ~/.bashrc && \
  source ~/.bashrc
```

### zsh

```bash
curl -o ~/.kc.sh -L https://raw.githubusercontent.com/teymurgahramanov/kc/v1.4.0/kc.sh && \
  sed -i '' '/source ~\/\.kc\.sh/d' ~/.zshrc 2>/dev/null; \
  echo "source ~/.kc.sh" >> ~/.zshrc && \
  source ~/.zshrc
```

> On Linux (GNU sed), drop the `''` after `-i` in the zsh command above.

## Use

1. Drop your kubeconfig files into `~/.kube/`.
2. Run `kc -g` to merge them into `~/.kube/config`.
3. Run `kc -l` to list contexts, then `kc -u <number>` to switch.

Run `kc -h` for the full list of options.

## Development

Static analysis and tests run in CI on every pull request.

```bash
# Lint
shellcheck kc.sh

# Test (requires bats-core)
bats test
```

The demo is reproducible via `demo.sh`, which runs an isolated walkthrough
(`kc -g` → `kc -l` → `kc -u` → `kc -n`) with throwaway sample clusters, so your
real `~/.kube/config` is never touched. Pace it with `TYPE_SPEED` / `STEP_PAUSE`.

```bash
asciinema rec -f asciicast-v2 -c "bash demo.sh" demo.cast
svg-term --in demo.cast --out demo.svg --window --width 90 --height 22
```

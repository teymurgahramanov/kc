# kc

__kc__ is the `kubectl` contexts manager, written in pure Bash, that makes switching between contexts, adding new ones, and modifying them easy and fast. It's ideal for those managing multiple Kubernetes clusters and relying on the terminal.

<p align="center">
    <img src="demo.svg" style="width: 90%; height: auto;" />
</p>

## Features

🔢 Easily switch between kubectl contexts using numbers.

🧩 Add new kubeconfig files with just a single command.

⭕ Easily set the default namespace for context.

⚠️ Always know which cluster you are in with the dynamic shell prompt.

🚨 Helps you to avoid making mistakes by highlighting production clusters in __red__.

👍 Light, without any dependencies, and installed with a single command.

🐚 Works with both __bash__ and __zsh__ (Linux and macOS).

## Install

### bash

```bash
curl -o ~/.kc.sh -L https://raw.githubusercontent.com/teymurgahramanov/kc/v1.4.0/kc.sh && \
  sed -i '/source ~\/\.kc\.sh/d; /source ~\/kc\.sh/d' ~/.bashrc && \
  echo "source ~/.kc.sh" >> ~/.bashrc && \
  source ~/.bashrc
```

### zsh

```bash
curl -o ~/.kc.sh -L https://raw.githubusercontent.com/teymurgahramanov/kc/v1.4.0/kc.sh && \
  sed -i '' '/source ~\/\.kc\.sh/d; /source ~\/kc\.sh/d' ~/.zshrc 2>/dev/null; \
  echo "source ~/.kc.sh" >> ~/.zshrc && \
  source ~/.zshrc
```

> On Linux (GNU sed), drop the `''` after `-i` in the zsh command above.

## Use

1. Place your kubeconfig files in the `~/.kube/` directory.
2. Execute `kc -g` to generate a new unified kubeconfig file `~/.kube/config`.
3. Use `kc -l` to list all available kubeconfig contexts.
4. To switch contexts, run `kc -u` followed by the context number (for example, `kc -u 5`).
5. To delete a context, run `kc -d` followed by the context number.
6. To set the default namespace for the current context, run `kc -n <namespace>`.
7. Run `kc -v` to print the version, or `kc -h` to view the help menu.

## Development

Static analysis and tests run in CI on every pull request.

```bash
# Lint
shellcheck kc.sh

# Test (requires bats-core)
bats test
```

### Recording the demo

The demo is reproducible via `demo.sh`, which runs an isolated walkthrough
(`kc -g` → `kc -l` → `kc -u` → `kc -n`) with throwaway sample clusters, so your
real `~/.kube/config` is never touched. Pace it with `TYPE_SPEED` / `STEP_PAUSE`.

Record it with [asciinema](https://asciinema.org):

```bash
asciinema rec -c "bash demo.sh" demo.cast
```

Then publish it using one of:

```bash
# 1) Inline animated SVG in this README (no external service)
#    npm i -g svg-term-cli
#    svg-term reads asciicast v1/v2 only, so convert the v3 recording first
#    (asciinema 3.x records v3 by default).
asciinema convert -f asciicast-v2 demo.cast demo-v2.cast
svg-term --in demo-v2.cast --out demo.svg --window --width 90 --height 22

# 2) Regenerate a (much smaller, sharper) GIF from the cast
#    https://github.com/asciinema/agg (agg reads v2 and v3 directly)
agg demo.cast demo.gif

# 3) Upload and get a shareable, interactive player
asciinema upload demo.cast
```

The README currently embeds the self-hosted `demo.svg` (option 1). To use an
uploaded cast instead (option 3), replace the image at the top of this file with:

```markdown
[![asciicast](https://asciinema.org/a/<CAST_ID>.svg)](https://asciinema.org/a/<CAST_ID>)
```

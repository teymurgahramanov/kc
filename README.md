# kc

__kc__ is the `kubectl` contexts manager, written in pure Bash, that makes switching between contexts, adding new ones, and modifying them easy and fast. It's ideal for those managing multiple Kubernetes clusters and relying on the terminal.

<p align="center">
    <img src="demo.gif" style="width: 90%; height: auto;" />
</p>

## Features

🔢 Easily switch between kubectl contexts using numbers.

🧩 Merge multiple kubectl config files into one with just a single command.

⚠️ Always know which cluster you are in with the dynamic shell prompt.

🚨 Helps you to avoid making mistakes by highlighting production clusters in red.

👍 Light, without any dependencies, and installed with a single command.
  
## Install
```bash
curl -o ~/.kc.sh -L https://raw.githubusercontent.com/teymurgahramanov/kc/v1.3.0/kc.sh && \
  sed -i '/source ~\/\.kc\.sh/d; /source ~\/kc\.sh/d' ~/.bashrc && \
  echo "source ~/.kc.sh" >> ~/.bashrc && \
  source ~/.bashrc
```

## Use
1. Place your kubeconfig files in the `~/.kube/` directory.
2. Execute `kc -g` to generate a new unified kubeconfig file `~/.kube/config`.
3. Use `kc -l` to list all available kubeconfig contexts.
4. To switch contexts, run `kc -u` followed by the context number (for example, `kc -u 5`).
5. For additional options, run `kc -h` to view the help menu.

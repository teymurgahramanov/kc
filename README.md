# kc - Easy Kubernetes context manager with smart PS1

kc is a Bash script that simplifies the management of Kubernetes configuration contexts making it convenient to work with many different clusters. It provides an easy way to merge and switch between contexts, list available contexts, and enhance your command prompt with context information.

![](./demo.gif)
## Features:
- Merge multiple Kubernetes configuration context files with just a single command.
- Easily switch between contexts using indexes instead of full context names.
- Always know the current context with dynamically updated command prompt (PS1) and differentiate "production" ones by color.
  
## Install
```
curl -o ~/kc.sh -L https://raw.githubusercontent.com/teymurgahramanov/kc/main/kc.sh && \
  echo "source ~/kc.sh" >> ~/.bashrc && \
  source ~/.bashrc
```

## Usage
Look at "help"
```
kc -h
```

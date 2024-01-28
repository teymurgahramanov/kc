# kc - Smart kubectl context manager

kc simplifies the management of Kubernetes configuration contexts making it convenient for those who work with many different clusters. It provides an easy way to merge and switch between contexts, list available contexts, and enhance your command prompt with context information.

![](./demo.gif)
## Features:
- Merge multiple Kubernetes configuration context files with just a single command.
- Easily switch between contexts using indexes instead of names.
- Always know the current context with dynamically updated prompt.
- Avoid Production clusters are higlihted with another color to prevent.
- Pure bash and install with single command.
  
## Install
```
curl -o ~/kc.sh -L https://raw.githubusercontent.com/teymurgahramanov/kc/v1.2.0/kc.sh && \
  echo "source ~/kc.sh" >> ~/.bashrc && \
  source ~/.bashrc
```

## Usage
Look at "help"
```
kc -h
```

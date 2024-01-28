# kc - Perfect tool for DevOps engineers who manage multiple Kubernetes clusters.

__kc__ simplifies the management of kubectl configuration contexts making tasks such as switching between contexts, adding new ones, and modifying them easy and fast.

![](./demo.gif)
## Features:

- Easily switch between contexts using number instead of name.
- Merge multiple kubectl config files into one with just a single command.
- Always know in which cluster you are with dynamically updated shell prompt.
- Helps you to avoid making mistakes by highlighting production clusters in red.
- Written on bash and will be installed with single command.
  
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

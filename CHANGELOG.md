# Changelog

## [1.3.0] - 2025-05-26

### Added
- `kc -n` to set default namespace in current context.
- Highlighting for the current context.

### Changed
- Improved `kc -g`. Now, it's enough to place a kubeconfig file under `~/.kube/`.
- Improved integration with shell prompt. Now, the current kubeconfig context name is appended to the shell prompt instead of modifying it.

### Removed
- `kc -m` for modifying context parameters. Instead, set them in your kubeconfig file and run `kc -g`.
- `kc -r` for renaming context name. Instead, rename your kubeconfig file and run `kc -g`.

## [1.2.0] - 2024-01-28

## [1.1.0] - 2023-10-06

## [1.0.0] - 2023-10-02

# Changelog

## [1.4.0] - 2026-07-12

### Added
- `kc -v` to print the version.
- Native `zsh` support via `precmd` prompt hook (in addition to `bash`).
- MIT `LICENSE`.
- Continuous integration: `shellcheck` static analysis and `bats` tests.
- `demo.sh`, a reproducible, isolated walkthrough for recording the demo (e.g. with asciinema).

### Fixed
- Off-by-one bug where `kc -u 0` (and other invalid indexes) silently selected
  the wrong context; indexes are now validated correctly.
- `kc -u`/`kc -d` now reject missing or non-numeric arguments.
- `kc -g` now works on macOS by using a portable `sed -i` (GNU and BSD).
- Filenames containing spaces are now handled correctly in `kc -g`.
- `kc_check` now returns a correct exit status when there is no current context.
- Functions are now safe to run under `set -u` (missing arguments no longer trip "unbound variable").

### Changed
- Prompt integration captures the original prompt once instead of rewriting it
  with a fragile regex on every render (bash and zsh).
- Internal variables are now scoped with `local` to avoid polluting the shell.
- Errors are printed to `stderr`.

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

### Changed
- Maintenance and stability improvements.

## [1.1.0] - 2023-10-06

### Changed
- Maintenance and stability improvements.

## [1.0.0] - 2023-10-02

### Added
- Initial release.

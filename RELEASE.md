# kc v1.5.0

The prompt now shows the current namespace alongside the context as
`(context:namespace)`, and you can toggle the prompt info with `kc -p [0|1]`
— the setting persists via `~/.kc.env` across all open shells.

**BREAKING:** the context-switch option was renamed from `-u` to `-c`
(`kc -c NUMBER`).

#!/usr/bin/env bats

# Tests for kc.sh. A fake `kubectl` is placed on PATH so the tests do not
# require a real Kubernetes setup.

setup() {
  ROOT_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  TMPBIN="$(mktemp -d)"
  export TMPBIN

  cat > "$TMPBIN/kubectl" <<'SH'
#!/usr/bin/env bash
args="$*"
case "$args" in
  "config current-context")
    echo "bravo"
    ;;
  "config get-contexts -o name")
    printf 'alpha\nbravo\nprod-cluster\n'
    ;;
  "config get-contexts")
    printf 'CURRENT   NAME           CLUSTER        AUTHINFO       NAMESPACE\n'
    printf '          alpha          a-cl           a-user\n'
    printf '*         bravo          b-cl           b-user\n'
    printf '          prod-cluster   p-cl           p-user\n'
    ;;
  "config use-context "*)
    echo "Switched to context \"${3}\"."
    ;;
  "config delete-context "*)
    echo "deleted context ${3}"
    ;;
  "config set-context --current --namespace="*)
    echo "Context modified."
    ;;
  *)
    exit 0
    ;;
esac
SH
  chmod +x "$TMPBIN/kubectl"
  PATH="$TMPBIN:$PATH"

  # shellcheck source=/dev/null
  source "$ROOT_DIR/kc.sh"
}

teardown() {
  rm -rf "$TMPBIN"
}

@test "no option prints an error" {
  run kc_main
  [ "$status" -ne 0 ]
  [[ "$output" == *"Provide an option"* ]]
}

@test "unknown option prints an error" {
  run kc_main -x
  [ "$status" -ne 0 ]
  [[ "$output" == *"Wrong option"* ]]
}

@test "-v prints the version" {
  run kc_main -v
  [ "$status" -eq 0 ]
  [[ "$output" == *"kc v"* ]]
}

@test "-h prints usage" {
  run kc_main -h
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: kc OPTION ARGUMENT"* ]]
}

@test "-l lists and numbers contexts starting at 1" {
  run kc_main -l
  [ "$status" -eq 0 ]
  [[ "$output" == *"N CURRENT"* ]]
  [[ "$output" == *"1 "* ]]
  [[ "$output" == *"alpha"* ]]
  [[ "$output" == *"prod-cluster"* ]]
}

@test "-u with non-numeric argument errors" {
  run kc_main -u abc
  [ "$status" -ne 0 ]
  [[ "$output" == *"valid context number"* ]]
}

@test "-u with missing argument errors" {
  run kc_main -u
  [ "$status" -ne 0 ]
  [[ "$output" == *"valid context number"* ]]
}

@test "-u 0 is rejected as out of range" {
  run kc_main -u 0
  [ "$status" -ne 0 ]
  [[ "$output" == *"Wrong index"* ]]
}

@test "-u out-of-range index errors" {
  run kc_main -u 999
  [ "$status" -ne 0 ]
  [[ "$output" == *"Wrong index"* ]]
}

@test "-u selects the correct context by number" {
  run kc_main -u 1
  [ "$status" -eq 0 ]
  [[ "$output" == *"alpha"* ]]
}

@test "-u selects the last context by number" {
  run kc_main -u 3
  [ "$status" -eq 0 ]
  [[ "$output" == *"prod-cluster"* ]]
}

@test "-d deletes the correct context by number" {
  run kc_main -d 2
  [ "$status" -eq 0 ]
  [[ "$output" == *"bravo"* ]]
}

@test "-n without namespace errors" {
  run kc_main -n
  [ "$status" -ne 0 ]
  [[ "$output" == *"Provide a namespace"* ]]
}

@test "-n sets the namespace" {
  run kc_main -n myns
  [ "$status" -eq 0 ]
  [[ "$output" == *"Context modified"* ]]
}

@test "kc_sanitize normalizes name/cluster/user/current-context fields" {
  cfg="$TMPBIN/My Cluster.yaml"
  cat > "$cfg" <<'YAML'
apiVersion: v1
current-context: something-else
clusters:
- cluster:
    server: https://example
  name: original-cluster-name
contexts:
- context:
    cluster: original-cluster-name
    user: original-user
  name: original-context
users:
- name: original-user
YAML
  run kc_sanitize "$cfg"
  [ "$status" -eq 0 ]
  # Field values should be replaced with the sanitized file name.
  grep -q "name: My-Cluster" "$cfg"
  grep -q "current-context: My-Cluster" "$cfg"
  grep -q "user: My-Cluster" "$cfg"
}

#!/usr/bin/env zsh
# Minimal self-contained test harness. Usage:
#   zsh tests/harness.zsh           # runs every tests/test_*.zsh
# Each test_*.zsh sources libs from $LLMM_LIB and calls assert_* helpers.
emulate -L zsh
set -u

typeset -g _tests=0 _fails=0

assert_eq() {  # assert_eq <got> <want> [label]
  (( _tests++ ))
  if [[ "$1" != "$2" ]]; then
    print -u2 "FAIL ${3:-assert_eq}: got [$1] want [$2]"
    (( _fails++ ))
  fi
}

assert_contains() {  # assert_contains <haystack> <needle> [label]
  (( _tests++ ))
  if [[ "$1" != *"$2"* ]]; then
    print -u2 "FAIL ${3:-assert_contains}: [$1] does not contain [$2]"
    (( _fails++ ))
  fi
}

assert_not_contains() {  # assert_not_contains <haystack> <needle> [label]
  (( _tests++ ))
  if [[ "$1" == *"$2"* ]]; then
    print -u2 "FAIL ${3:-assert_not_contains}: [$1] unexpectedly contains [$2]"
    (( _fails++ ))
  fi
}

assert_rc() {  # assert_rc <expected_rc> <actual_rc> [label]
  (( _tests++ ))
  if [[ "$1" != "$2" ]]; then
    print -u2 "FAIL ${3:-assert_rc}: expected rc $1 got $2"
    (( _fails++ ))
  fi
}

typeset -g LLMM_TESTS_DIR="${0:A:h}"
typeset -g LLMM_ROOT="${LLMM_TESTS_DIR:h}"
typeset -g LLMM_LIB="$LLMM_ROOT/lib"

for _t in "$LLMM_TESTS_DIR"/test_*.zsh(N); do
  source "$_t"
done

print "ran $_tests assertions, $_fails failure(s)"
(( _fails == 0 ))

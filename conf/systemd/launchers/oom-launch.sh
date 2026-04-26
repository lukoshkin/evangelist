#!/usr/bin/env bash
# Spawns the given command in a fresh user-level systemd transient scope
# carrying explicit OOM-related properties, so that systemd-oomd and the
# kernel OOM killer treat the launched process the way we want.
#
# Used by the .desktop overrides written by setup-app-priorities.sh.
#
# Usage:
#   oom-launch.sh <oom-score-adj> <managed-oom-preference> -- <argv...>
#
# Where:
#   <oom-score-adj>             integer in [-1000, 1000]; higher == kernel
#                               OOM killer prefers killing this process
#   <managed-oom-preference>    one of: none | avoid | omit
#                               'none' means: do not set the property at all
#                               'avoid' / 'omit' tell systemd-oomd to skip
#                               this scope when picking a kill target

set -e

score=${1:?usage: $0 <score> <pref> -- <cmd> [args...]}
pref=${2:?usage: $0 <score> <pref> -- <cmd> [args...]}
shift 2
[[ ${1-} = -- ]] && shift

args=(--user --scope --collect --slice=app.slice -p OOMScoreAdjust="$score")
[[ $pref = none ]] || args+=(-p ManagedOOMPreference="$pref")

exec systemd-run "${args[@]}" -- "$@"

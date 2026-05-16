#!/usr/bin/env bash
# Applies OOM properties to the given command via the cleanest available
# mechanism for each one:
#
#   * kernel oom_score_adj    -> 'choom -n N --'  (util-linux >= 2.32)
#                                or a /proc fallback if choom is absent.
#                                Inherited across the final exec.
#
#   * systemd-oomd preference -> '-p ManagedOOMPreference=...' on a transient
#                                user scope created by 'systemd-run --scope'.
#                                Only applied when pref != none, because:
#                                  (a) the [Scope] unit is what oomd reads
#                                      that property from;
#                                  (b) wrapping a snap-confined binary in a
#                                      transient scope is the kind of thing
#                                      snap-confine has historically been
#                                      finicky about, so we avoid it when
#                                      we don't strictly need it.
#
#   N.B. 'OOMScoreAdjust=' is NOT set via -p on systemd-run --scope.
#   That property belongs to [Service] units (it requires an Exec=line),
#   and --scope creates a [Scope] unit which rejects it with
#       Unknown assignment: OOMScoreAdjust=...
#   taking the whole launch down with it. Kernel score is therefore set
#   via 'choom' instead.
#
# Usage:
#   oom-launch.sh <oom-score-adj> <managed-oom-preference> -- <argv...>
#
#     <oom-score-adj>             integer in [-1000, 1000]
#     <managed-oom-preference>    one of: none | avoid | omit

set -e

score=${1:?usage: $0 <score> <pref> -- <cmd> [args...]}
pref=${2:?usage: $0 <score> <pref> -- <cmd> [args...]}
shift 2
[[ ${1-} = -- ]] && shift

## Build the inner command. We write to /proc/self/oom_score_adj instead of
## using 'choom' because non-root processes can only RAISE the score (lowering
## requires CAP_SYS_RESOURCE, which a regular GUI session does not have).
## 'choom' aborts the launch on permission denied; this fallback silently
## no-ops on the protected-terminal case (negative score) and lets the
## ManagedOOMPreference=avoid attached to the scope below carry the load.
inner=(bash -c 'echo "$1" >/proc/self/oom_score_adj 2>/dev/null; shift; "$@"' _ "$score")
inner+=("$@")

if [[ $pref = none ]]; then
  ## No oomd hint to attach -> no need for a transient scope. Run the
  ## command directly on whatever cgroup the .desktop launcher placed us
  ## on (i.e. let GNOME / KDE / sway own the scope, the way they normally
  ## do). This is the path slack / spotify / telegram / chrome take.
  "${inner[@]}"
else
  systemd-run \
    --user --scope --collect --slice=app.slice \
    -p ManagedOOMPreference="$pref" \
    -- "${inner[@]}"
fi

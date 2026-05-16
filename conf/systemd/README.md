# OOM Hardening

Configures `systemd-oomd` + kernel VM tuning so the laptop no longer hangs
when RAM + swap are exhausted. Diagnosed on Ubuntu 24.04 (XPS 13, 7.5 GB RAM,
4 GB disk swapfile): oomd was running but not actually killing anything
(`oomctl` showed empty `Swap Monitored CGroups`, no `ManagedOOM*=kill` set
anywhere), so the kernel would thrash on swap I/O until the UI froze.

## What it does

| File                                                    | Effect                                                                                                                     |
| ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| `/etc/systemd/oomd.conf.d/override.conf`                | Tightens oomd thresholds (pressure 60→50%, duration 30→20s) so it reacts before thrashing becomes irrecoverable. Swap limit kept at upstream default 90% to avoid premature kills when swap legitimately fills up. |
| `/etc/systemd/system/-.slice.d/10-oomd.conf`            | `ManagedOOMSwap=kill` on root slice → system-wide swap monitoring. Highest swap user gets killed (chrome/slack/spotify/telegram in practice) |
| `/etc/systemd/system/user@.service.d/10-oomd.conf`      | `ManagedOOMMemoryPressure=kill` on user manager → kills the app slice under pressure before OOM even happens               |
| `/etc/systemd/system/system.slice.d/10-oomd.conf`       | `ManagedOOMPreference=avoid` on `system.slice` → oomd skips system services (NetworkManager, dbus, …) and funnels kills into `user.slice` |
| `/etc/sysctl.d/99-swap.conf`                            | `vm.swappiness=20`, `vm.vfs_cache_pressure=50` — kernel stops diving into disk swap at the first sign of pressure          |

Terminal survival is implicit: oomd picks the cgroup with the *most* swap/pressure,
and Electron-class apps (chrome, slack, spotify, telegram, vscode) always dwarf
the terminal, so the terminal is essentially never the chosen target.

## Per-app bias (`.desktop` overrides + user-level service drop-ins)

`systemd-oomd` itself has **no "kill these first" knob** — its only per-unit
preference is `none|avoid|omit`, and selection among non-skipped cgroups is
purely usage-based. To get as close as possible to *"kill chrome / slack /
spotify / telegram first, kill the terminal last"*, `setup-app-priorities.sh`
writes user-level `.desktop` overrides into `~/.local/share/applications/`.
Each override re-launches its app through `launchers/oom-launch.sh`, which
uses `systemd-run --user --scope` to attach explicit OOM properties to the
resulting transient scope:

| app group                                  | `OOMScoreAdjust` | `ManagedOOMPreference` | effect                                                                  |
| ------------------------------------------ | ---------------- | ---------------------- | ----------------------------------------------------------------------- |
| chrome, slack, spotify, telegram, chromium | `+500`           | `none`                 | kernel-OOM safety net; oomd already prefers them by usage               |
| kitty, alacritty, wezterm, foot, terminator, tilix, gnome-terminal | `-500` | `avoid` | oomd actively deprioritises these scopes when picking a victim          |

### `avoid` is not `omit` — by design

`avoid` deprioritises but does **not** immortalise. If the protected terminal
is itself the actual runaway (or every other candidate is already gone),
`oomd` will still kill it. That's intentional: a true memory blow-up should
end with a dead terminal, not a frozen laptop. `omit` (which would make oomd
never pick the cgroup) is deliberately not used for terminals here — change
it via `custom/oom-priorities.list` if you really want a terminal that
oomd refuses to touch.

### The gnome-terminal caveat (D-Bus activation)

GNOME Terminal launches via D-Bus: the binary you ran from the `.desktop`
just sends a message to `gnome-terminal-server.service` and exits, while the
real window/process tree lives inside that service. The `.desktop` wrap
alone therefore doesn't protect any actual terminal process. To cover that
case, `setup-app-priorities.sh` also writes a user-level systemd drop-in
under `~/.config/systemd/user/gnome-terminal-server.service.d/10-oomd.conf`
when the service is present, then runs `systemctl --user daemon-reload`.

### Customisation

Drop a file at `$EVANGELIST/custom/oom-priorities.list` with one tuple per
line, format `<basename>:<oom-score>:<managed-oom-preference>`, to add new
apps or change defaults. Lines starting with `#` are ignored. The last
tuple sharing a basename wins.

```text
# example custom/oom-priorities.list
discord:500:none           # add discord to the kill-first list
signal-desktop:300:none    # tap signal-desktop a bit
kitty:-1000:omit           # make kitty literally untouchable by oomd
                           #  (re-introduces the freeze risk; only use this
                           #   if you have another safety net)
```

`setup-app-priorities.sh` runs as your user (no sudo); `evn install systemd`
calls it automatically. Overrides only land for apps that are actually
installed (search order: `/usr/local/share/applications`, `/usr/share/applications`,
`/var/lib/snapd/desktop/applications`, then flatpak dirs). Every generated
file starts with `# Generated by evangelist (oom-priority)` so `evn uninstall`
can find and remove them safely.

## Install

```sh
sudo bash apply.sh
```

Verify:

```sh
oomctl
```

You should see:
- `Swap Monitored CGroups:` populated with `/` and descendants
- `ManagedOOMMemoryPressure: kill` on `user@1000.service`

## zram (recommended follow-up)

Even with oomd working well, disk swap can saturate I/O before oomd reacts. zram
is compressed RAM swap — same role as disk swap, but lives in RAM, compresses
~2-3× with zstd, and has no I/O thrash.

```sh
sudo bash setup-zram.sh
```

## Rollback

System-wide drop-ins (sudo):

```sh
sudo rm -f \
  /etc/systemd/oomd.conf.d/override.conf \
  /etc/systemd/system/-.slice.d/10-oomd.conf \
  /etc/systemd/system/user@.service.d/10-oomd.conf \
  /etc/systemd/system/system.slice.d/10-oomd.conf \
  /etc/sysctl.d/99-swap.conf
sudo systemctl daemon-reload
sudo systemctl restart systemd-oomd
sudo sysctl --system
```

Per-user `.desktop` overrides and systemd drop-ins (no sudo):

```sh
grep -lr 'Generated by evangelist (oom-priority)' \
  "${XDG_DATA_HOME:-$HOME/.local/share}/applications" 2>/dev/null \
  | xargs -r rm -f

find "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user" \
  -name 10-oomd.conf -exec grep -l 'Generated by evangelist (oom-priority)' {} + 2>/dev/null \
  | xargs -r rm -f
systemctl --user daemon-reload
```

`evn uninstall` does both automatically when systemd was installed via evn.

For zram: `sudo systemctl disable --now zramswap.service && sudo apt remove zram-tools`.

## Files in this directory

```
.
├── README.md                   # this file
├── apply.sh                    # installs the /etc/ drop-ins + reloads systemd
├── setup-zram.sh               # optional: installs + enables zram swap
├── setup-app-priorities.sh     # writes user-level .desktop overrides + per-service drop-ins
├── launchers/
│   └── oom-launch.sh           # systemd-run wrapper invoked by the .desktop overrides
└── files/                      # mirror of /etc/ targets (source of truth)
    └── etc/
        ├── systemd/
        │   ├── oomd.conf.d/override.conf
        │   └── system/
        │       ├── -.slice.d/10-oomd.conf
        │       ├── user@.service.d/10-oomd.conf
        │       └── system.slice.d/10-oomd.conf
        └── sysctl.d/99-swap.conf
```

User-side files written at install time (managed by `setup-app-priorities.sh`):

```
$XDG_DATA_HOME/applications/*.desktop                          # per-app overrides
$XDG_CONFIG_HOME/systemd/user/<service>.d/10-oomd.conf         # D-Bus terminal protection
$EVANGELIST/custom/oom-priorities.list                         # optional user customisation
```

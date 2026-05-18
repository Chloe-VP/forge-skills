---
name: weekly-infra-maintenance
description: "Set up safe, recurring (e.g. weekly) Tier-1 maintenance across a small multi-host fleet of macOS + Linux machines. Applies updates that never require reboot or daemon restart (brew, security apt, docker image refresh), explicitly holds back kernel/cuda/containerd/docker-daemon/nvidia packages, surfaces reboot-required and macOS major-version backlog as ACTION lines, and reports via Telegram. Use when: you have 2–5 hosts to keep current, want a scheduled job that won't break things while you sleep, and want a single summary report. NOT for: one-off ad-hoc upgrades, hosts that need different policies, or anything that should auto-reboot."
metadata: { "openclaw": { "emoji": "🛠" } }
---

# Weekly Infra Maintenance

A pattern + reference script for safe scheduled maintenance across a small
fleet (the example covers one driver Mac + one peer Mac + one Linux box, but
the structure is host-agnostic).

The core idea is the **Tier 1 / 2 / 3 model**:

| Tier | Definition | Automation policy |
|---|---|---|
| **1** | Will not reboot, will not restart long-running daemons | Apply silently each run |
| **2** | Requires daemon restart or kernel reboot to take effect | Install but report; surface in ACTION block |
| **3** | Major version bumps (macOS, distro release) | Never auto-install; surface as backlog |

Examples by host class:

- **macOS:** `brew update && brew upgrade` is Tier 1. `softwareupdate -i` for any
  pending macOS update is Tier 3 (defer).
- **Linux (apt):** security/minor pkg upgrades are Tier 1, but **the daemon
  packages must be held back** — `linux-*`, `containerd*`, `docker-ce*`,
  `docker-buildx*`, `docker-compose*`, `cuda-*`, `nvidia-*`, `libnvidia*`,
  `libcuda*` are all Tier 2.
- **Docker:** `docker pull` for every named-tag image is Tier 1 (just refreshes
  the local cache; doesn't touch running containers). `docker image prune -f`
  (dangling only, not `-a`) reclaims layer space without deleting tagged images
  that may be intentionally pinned. Restarting containers to pick up the new
  images is Tier 2 — leave that to the operator.

## When to Use

✅ Use this skill when:

- A small fleet (2–5 hosts) needs current packages and you want a single
  scheduled job that runs unattended
- You want a single Telegram / Slack / email summary, not log-watching
- You're OK leaving major upgrades (macOS, kernel) for an interactive session

❌ Don't use when:

- The fleet is large enough that you should be using configuration management
  (Ansible, Salt, Chef) — this is a glorified shell script, not infra-as-code
- You need true zero-downtime container updates (use Watchtower, kured, etc.)
- A host has bespoke upgrade rules that can't fit a regex-based holdback

## Setup Walkthrough

1. **Driver host.** Pick the macOS box that will own the cron/launchd job and
   SSH out to the peers. It needs:
   - Passwordless SSH key to every peer
   - All peers must accept `sudo -n` for their package manager
     (`echo "user ALL=(ALL) NOPASSWD: /usr/bin/apt-get, /usr/bin/dpkg" | sudo tee /etc/sudoers.d/maintenance` on Linux peers)
   - Homebrew at `/opt/homebrew/bin/brew` (Apple Silicon path; rewrite if Intel)

2. **Install the script.** Copy `references/weekly-maintenance.sh` to
   `~/bin/weekly-maintenance.sh`, chmod +x. Edit the CONFIG block at the top to
   list your hosts (separated into the `MACOS_PEERS` and `LINUX_PEERS` arrays)
   and the apt holdback regex.

3. **Notification channel.** The script reads a `.env` for the Telegram bot
   token + chat id. If you don't want Telegram, comment out `tg_send_chunked`
   at the bottom of the summary section.

4. **Schedule it.** Copy `references/launchd-template.plist` to
   `~/Library/LaunchAgents/com.<you>.weekly-maintenance.plist`, edit the
   `<Label>`, paths, and `<StartCalendarInterval>` weekday/hour, then
   `launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.<you>.weekly-maintenance.plist`.
   `launchctl print gui/$UID/com.<you>.weekly-maintenance` to verify.

5. **Sleep-wake belt-and-suspenders.** macOS `launchd` skips firings while the
   Mac is asleep and does NOT catch up. If your driver host can sleep, add a
   wake event 5 min before the schedule:
   ```
   sudo pmset repeat wakeorpoweron W 07:55:00
   ```
   (`W` = Wednesday; `MTWRFSU` codes documented in `man pmset`.) Skip this if
   your driver host already has system sleep disabled.

6. **First run, foreground.** Run `~/bin/weekly-maintenance.sh` manually before
   trusting it to the schedule. Look for unexpected hold-back items, daemon
   upgrades that snuck through, or empty docker pull counts (see Gotchas).

## Gotchas Worth Knowing

### 1. SSH inside `while read` eats stdin

```bash
while IFS= read -r img; do
  ssh host "docker pull '$img'"   # <-- this ssh inherits stdin from the read loop
done < <(ssh host "docker images")  # ...and consumes everything but iteration 1
```

After iteration 1 the inner `ssh` has gulped the rest of the producer's output.
Loop silently stops with no error. Fix: `ssh -n` (or `< /dev/null`) on the
inner ssh. Same trap applies to `mysql -e`, `curl --upload`, anything that
defaults to reading stdin. If a loop "stops after iter 1 with no errors,"
suspect this first.

### 2. `docker-ce` is a daemon-restart trap

The first version of our script held back `containerd` and `cuda-*` but not
`docker-ce` / `docker-buildx-plugin` / `docker-compose-plugin`. apt happily
upgraded docker-ce 28→29, which bounced the daemon and restarted every
container. Tier 1 should hold `^(docker-ce|docker-buildx|docker-compose)` too.

### 3. `docker image prune -a` is too aggressive

`-a` removes any image not currently in use by a running container — which will
nuke intentionally-pinned reference images (an old pytorch tag you keep around
for reproducing a job, say). Use `docker image prune -f` (dangling-only) for
weekly cron. Use `-a` interactively when you know what you're killing.

### 4. macOS `launchd` and sleep

Already covered above — `StartCalendarInterval` does not catch up after a
missed firing. If you can't run `pmset repeat`, fall back to a `StartInterval`
with idempotency in the script (re-running it daily is harmless and provides
catch-up).

### 5. Reboot-pending visibility

On Ubuntu, `test -f /var/run/reboot-required` is the canonical signal — pkgs
that triggered it are in `/var/run/reboot-required.pkgs`. The script checks
both and adds an ACTION line.

For "kernel installed but not booted," compare `uname -r` against the latest
`linux-image-*` package version. macOS doesn't have a clean equivalent;
treating any non-empty `softwareupdate -l` as Tier 3 is the practical proxy.

### 6. ACTION lines first

The summary block leads with an `ACTION REQUIRED:` section listing
reboot-pending hosts and pending macOS updates. Burying these at the bottom of
a weekly summary means they get ignored — the Telegram chunking pushes the
later items off the screen.

## Tier 2 / Tier 3 Upgrade Sessions

Don't let the held items rot. Once a quarter (or whenever the ACTION list
piles up), do an interactive session that:

1. Reads the ACTION block from the last summary
2. Drives macOS major upgrades on each Mac (interactive, expect reboot)
3. On Linux, `sudo apt full-upgrade` to pull kernel/cuda/containerd, then
   `sudo reboot`
4. Watch containers come back, check `nvidia-smi`, etc.

This skill is deliberately scoped to Tier 1 only because that's the part you
can safely automate. Tier 2/3 wants a human.

## Files

- `references/weekly-maintenance.sh` — fully working reference; edit the CONFIG
  block at the top before installing
- `references/launchd-template.plist` — Wed 8am example; edit `<Label>`, paths,
  and weekday/hour

## Exit Codes

The reference script:

- `0` — clean run; Tier 1 completed on every reachable host
- `1` — another instance is already running (flock)
- `2` — at least one hard failure (SSH down, brew/apt returned non-zero)

Per-image docker pull failures for local-only images (no registry) are
**expected** and do not count as hard failures — they're reported as
`pulled N / M fail` for visibility.

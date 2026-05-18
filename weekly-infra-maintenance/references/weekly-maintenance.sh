#!/usr/bin/env bash
# Weekly maintenance: Tier 1 (safe, no reboots) across a small host fleet.
# Requires bash 4+ (associative arrays). macOS ships 3.2; use `brew install bash`
# or change the per-peer arrays to plain variables if you must run system bash.
# Triggered by launchd (macOS) or systemd timer / cron (Linux driver).
#
# Tier 1 scope:
#   - macOS peers: brew update && brew upgrade
#   - Linux peers: apt upgrade EXCLUDING kernel / containerd / docker-daemon /
#                  cuda / nvidia (see APT_HOLDBACK_RE below)
#   - Docker:      docker pull for all named-tag images, then `image prune -f`
#                  (dangling only — never tagged images that may be pinned)
#   - Report Tier 2 (held packages) + Tier 3 (macOS major) + reboot-pending
#
# Notifications: full log to $LOG_DIR + chunked Telegram summary if a
# .env with TELEGRAM_BOT_TOKEN + TELEGRAM_CHAT_ID is available.
#
# Exit codes:
#   0 = clean (Tier 1 completed on every reachable host)
#   1 = another instance already running
#   2 = at least one host had a hard failure

set -u
umask 077

# ────────────────────────────────────────────────────────────────────────────
# CONFIG — edit these for your fleet
# ────────────────────────────────────────────────────────────────────────────

# SSH aliases. Driver host (this machine) is implicit. Empty arrays are fine.
MACOS_PEERS=( )                  # e.g. ( mini2 mini3 )
LINUX_PEERS=( )                  # e.g. ( spark gpu-rig )

# Path to Homebrew (Apple Silicon default — adjust for Intel: /usr/local/bin/brew)
BREW=/opt/homebrew/bin/brew

# Apt packages to hold back (Tier 2 — reported but not installed).
# Anchored regex against the package name (no version suffix).
APT_HOLDBACK_RE='^(linux-|containerd|docker-ce|docker-buildx|docker-compose|cuda-|nvidia-|libnvidia|libcuda)'

# Notification env file. Must export TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID.
# Set to "" to skip Telegram entirely.
TG_ENV_FILE="$HOME/.config/weekly-maintenance.env"

# ────────────────────────────────────────────────────────────────────────────
# End config
# ────────────────────────────────────────────────────────────────────────────

LOG_DIR="$HOME/Library/Logs/weekly-maintenance"   # macOS path; use ~/.local/state/weekly-maintenance on Linux
mkdir -p "$LOG_DIR"
TS="$(date +%Y%m%d-%H%M%S)"
LOG="$LOG_DIR/run-$TS.log"
SUMMARY="$LOG_DIR/summary-$TS.txt"

SSH_OPTS=(-o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=30)

HARD_FAIL=0
ACTIONS=()

# --- lock (prevent overlapping runs) ----------------------------------------

LOCK_DIR="$HOME/.cache/weekly-maintenance"
mkdir -p "$LOCK_DIR"
LOCKFILE="$LOCK_DIR/run.lock"
if ! ( set -o noclobber; printf '%s\n' "$$" > "$LOCKFILE" ) 2>/dev/null; then
  prev_pid=$(cat "$LOCKFILE" 2>/dev/null || echo "?")
  if [[ "$prev_pid" =~ ^[0-9]+$ ]] && kill -0 "$prev_pid" 2>/dev/null; then
    printf 'previous run still active (pid %s); exiting\n' "$prev_pid" >&2
    exit 1
  fi
  printf '%s\n' "$$" > "$LOCKFILE"
fi
trap 'rm -f "$LOCKFILE"' EXIT

# --- helpers -----------------------------------------------------------------

log()    { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG"; }
section(){ printf '\n=== %s ===\n' "$*" | tee -a "$LOG"; }
fail()   { HARD_FAIL=1; log "HARD FAIL: $*"; }
action() { ACTIONS+=("$*"); }

tg_send() {
  local text="$1"
  [[ -n "$TG_ENV_FILE" && -r "$TG_ENV_FILE" ]] || return 0
  set -a; . "$TG_ENV_FILE"; set +a
  [[ -n "${TELEGRAM_BOT_TOKEN:-}" && -n "${TELEGRAM_CHAT_ID:-}" ]] || return 0
  curl -sS --max-time 15 \
    "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" \
    --data-urlencode "text=${text}" >/dev/null 2>&1 || true
}

tg_send_chunked() {
  local text="$1" chunk
  while [[ -n "$text" ]]; do
    chunk="${text:0:3800}"
    text="${text:3800}"
    tg_send "$chunk"
    [[ -n "$text" ]] && sleep 1
  done
}

# --- 1. driver brew + docker -------------------------------------------------

driver_pulled=0; driver_failed=0; driver_pruned=""
driver_before=0; driver_after=0
driver_macos_pending=""

if [[ -x "$BREW" ]]; then
  section "driver (this host) — brew"
  driver_before=$($BREW outdated --quiet | wc -l | tr -d ' ')
  log "driver: $driver_before outdated before"
  $BREW update         >>"$LOG" 2>&1 || fail "driver brew update"
  $BREW upgrade        >>"$LOG" 2>&1 || fail "driver brew upgrade"
  $BREW upgrade --cask >>"$LOG" 2>&1 || fail "driver brew upgrade --cask"
  $BREW cleanup -s     >>"$LOG" 2>&1
  driver_after=$($BREW outdated --quiet | wc -l | tr -d ' ')
  log "driver: $driver_after outdated remaining"

  if command -v softwareupdate >/dev/null 2>&1; then
    driver_macos_pending=$(softwareupdate -l 2>&1 | grep -E '^\* Label:' | sed 's/^\* Label: //')
    if [[ -n "$driver_macos_pending" ]]; then
      log "driver pending macOS updates (manual):
$driver_macos_pending"
      action "driver: macOS update(s) waiting: $(echo "$driver_macos_pending" | head -1)"
    fi
  fi
fi

if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  section "driver — docker image refresh"
  while IFS= read -r img; do
    [[ "$img" == *":<none>"* || "$img" == "<none>"* ]] && continue
    if docker pull -q "$img" </dev/null >>"$LOG" 2>&1; then
      driver_pulled=$((driver_pulled+1))
    else
      driver_failed=$((driver_failed+1))
    fi
  done < <(docker images --format '{{.Repository}}:{{.Tag}}')
  driver_pruned=$(docker image prune -f 2>>"$LOG" | tail -1 | sed 's/Total reclaimed space: //')
  log "driver docker: pulled $driver_pulled, $driver_failed failed (likely local-only); reclaimed ${driver_pruned:-0B}"
fi

# --- 2. macOS peers ----------------------------------------------------------

declare -A PEER_BREW_BEFORE PEER_BREW_AFTER PEER_MACOS_PENDING
for peer in "${MACOS_PEERS[@]}"; do
  section "$peer — brew"
  if ssh "${SSH_OPTS[@]}" "$peer" 'true' 2>/dev/null; then
    PEER_BREW_BEFORE[$peer]=$(ssh "${SSH_OPTS[@]}" "$peer" "/opt/homebrew/bin/brew outdated --quiet | wc -l | tr -d ' '" 2>/dev/null)
    log "$peer: ${PEER_BREW_BEFORE[$peer]:-?} outdated before"
    ssh "${SSH_OPTS[@]}" "$peer" '/opt/homebrew/bin/brew update && /opt/homebrew/bin/brew upgrade && /opt/homebrew/bin/brew upgrade --cask 2>&1; /opt/homebrew/bin/brew cleanup -s' >>"$LOG" 2>&1 \
      || fail "$peer brew upgrade"
    PEER_BREW_AFTER[$peer]=$(ssh "${SSH_OPTS[@]}" "$peer" "/opt/homebrew/bin/brew outdated --quiet | wc -l | tr -d ' '" 2>/dev/null)
    log "$peer: ${PEER_BREW_AFTER[$peer]:-?} outdated remaining"
    PEER_MACOS_PENDING[$peer]=$(ssh "${SSH_OPTS[@]}" "$peer" 'softwareupdate -l 2>&1 | grep "^\* Label:" | sed "s/^\* Label: //"' 2>/dev/null)
    if [[ -n "${PEER_MACOS_PENDING[$peer]:-}" ]]; then
      log "$peer pending macOS updates (manual):
${PEER_MACOS_PENDING[$peer]}"
      action "$peer: macOS update(s) waiting: $(echo "${PEER_MACOS_PENDING[$peer]}" | head -1)"
    fi
  else
    fail "$peer SSH unreachable, skipping"
    PEER_BREW_BEFORE[$peer]="?"; PEER_BREW_AFTER[$peer]="?"
  fi
done

# --- 3. Linux peers (apt + docker) ------------------------------------------

declare -A LINUX_TOTAL LINUX_APPLIED LINUX_HELD LINUX_REMAINING
declare -A LINUX_PULLED LINUX_FAILED LINUX_PRUNED LINUX_KERNEL
for peer in "${LINUX_PEERS[@]}"; do
  section "$peer — apt (safe set)"
  if ssh "${SSH_OPTS[@]}" "$peer" 'true' 2>/dev/null; then
    ssh "${SSH_OPTS[@]}" "$peer" 'sudo -n apt-get update' >>"$LOG" 2>&1 \
      || fail "$peer apt-get update"
    LINUX_TOTAL[$peer]=$(ssh "${SSH_OPTS[@]}" "$peer" "apt list --upgradable 2>/dev/null | grep -v '^Listing' | wc -l" 2>/dev/null)
    safe_list=$(ssh "${SSH_OPTS[@]}" "$peer" "apt list --upgradable 2>/dev/null | grep -v '^Listing' | cut -d/ -f1 | grep -vE '$APT_HOLDBACK_RE'" 2>/dev/null)
    LINUX_APPLIED[$peer]=$(printf '%s\n' "$safe_list" | grep -c .)
    LINUX_HELD[$peer]=$(( ${LINUX_TOTAL[$peer]:-0} - LINUX_APPLIED[$peer] ))
    log "$peer: ${LINUX_TOTAL[$peer]} upgradable — applying ${LINUX_APPLIED[$peer]}, holding ${LINUX_HELD[$peer]}"

    if [[ -n "$safe_list" ]]; then
      pkg_args=$(printf '%s ' $safe_list)
      ssh "${SSH_OPTS[@]}" "$peer" "sudo -n DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' install --only-upgrade $pkg_args" >>"$LOG" 2>&1 \
        || fail "$peer apt-get install --only-upgrade"
    fi
    LINUX_REMAINING[$peer]=$(ssh "${SSH_OPTS[@]}" "$peer" "apt list --upgradable 2>/dev/null | grep -v '^Listing' | wc -l" 2>/dev/null)

    # Reboot-required signal
    if ssh "${SSH_OPTS[@]}" "$peer" 'test -f /var/run/reboot-required' 2>/dev/null; then
      triggers=$(ssh "${SSH_OPTS[@]}" "$peer" 'cat /var/run/reboot-required.pkgs 2>/dev/null | head -3 | tr "\n" " "' 2>/dev/null)
      log "$peer: REBOOT REQUIRED (${triggers:-unknown})"
      action "$peer: REBOOT REQUIRED (${triggers:-pending updates}) — manual"
    fi

    # Kernel mismatch (new installed, not booted)
    krun=$(ssh "${SSH_OPTS[@]}" "$peer" 'uname -r' 2>/dev/null)
    klatest=$(ssh "${SSH_OPTS[@]}" "$peer" "dpkg --list 'linux-image-*' 2>/dev/null | awk '/^ii/ {print \$2}' | sed 's/^linux-image-//' | grep -E '^[0-9]' | sort -V | tail -1" 2>/dev/null)
    if [[ -n "$krun" && -n "$klatest" && "$krun" != "$klatest" ]]; then
      log "$peer: kernel mismatch — running $krun, installed $klatest"
      action "$peer: kernel $klatest installed, still running $krun — reboot to activate"
    fi
    LINUX_KERNEL[$peer]="running=$krun latest=$klatest"

    # Docker pulls (ssh -n required — see SKILL.md gotcha #1)
    section "$peer — docker image pulls (no container restart)"
    LINUX_PULLED[$peer]=0; LINUX_FAILED[$peer]=0
    while IFS= read -r img; do
      [[ -z "$img" || "$img" == *":<none>"* || "$img" == "<none>"* ]] && continue
      if ssh -n "${SSH_OPTS[@]}" "$peer" "docker pull -q '$img'" >>"$LOG" 2>&1; then
        LINUX_PULLED[$peer]=$((LINUX_PULLED[$peer]+1))
      else
        LINUX_FAILED[$peer]=$((LINUX_FAILED[$peer]+1))
      fi
    done < <(ssh -n "${SSH_OPTS[@]}" "$peer" "docker images --format '{{.Repository}}:{{.Tag}}'" 2>/dev/null)
    LINUX_PRUNED[$peer]=$(ssh -n "${SSH_OPTS[@]}" "$peer" "docker image prune -f 2>/dev/null | tail -1 | sed 's/Total reclaimed space: //'" 2>/dev/null)
    log "$peer docker: pulled ${LINUX_PULLED[$peer]}, ${LINUX_FAILED[$peer]} failed; reclaimed ${LINUX_PRUNED[$peer]:-0B}"
  else
    fail "$peer SSH unreachable, skipping"
  fi
done

# --- 4. summary --------------------------------------------------------------

section "summary"
{
  echo "Weekly maintenance run $TS"
  echo ""
  if (( ${#ACTIONS[@]} > 0 )); then
    echo "ACTION REQUIRED:"
    printf '  • %s\n' "${ACTIONS[@]}"
    echo ""
  fi
  echo "driver brew:   $driver_before → $driver_after outdated; docker pulled $driver_pulled/$driver_failed fail; reclaimed ${driver_pruned:-0B}"
  for peer in "${MACOS_PEERS[@]}"; do
    echo "$peer brew:   ${PEER_BREW_BEFORE[$peer]:-?} → ${PEER_BREW_AFTER[$peer]:-?} outdated"
  done
  for peer in "${LINUX_PEERS[@]}"; do
    echo "$peer apt:    ${LINUX_TOTAL[$peer]:-?} → ${LINUX_REMAINING[$peer]:-?} (applied ${LINUX_APPLIED[$peer]:-?}, held ${LINUX_HELD[$peer]:-?})"
    echo "$peer docker: pulled ${LINUX_PULLED[$peer]:-0}/${LINUX_FAILED[$peer]:-0} fail; reclaimed ${LINUX_PRUNED[$peer]:-0B}"
    [[ -n "${LINUX_KERNEL[$peer]:-}" ]] && echo "$peer kernel: ${LINUX_KERNEL[$peer]}"
  done
  echo ""
  echo "Exit: $([[ $HARD_FAIL -eq 0 ]] && echo OK || echo HARD_FAIL)"
  echo "Full log: $LOG"
} | tee "$SUMMARY"

tg_send_chunked "$(cat "$SUMMARY")"

# --- 5. log rotation: keep last 12 runs --------------------------------------

ls -1t "$LOG_DIR"/run-*.log     2>/dev/null | tail -n +13 | xargs rm -f 2>/dev/null || true
ls -1t "$LOG_DIR"/summary-*.txt 2>/dev/null | tail -n +13 | xargs rm -f 2>/dev/null || true

[[ $HARD_FAIL -eq 0 ]] && exit 0 || exit 2

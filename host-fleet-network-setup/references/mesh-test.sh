#!/usr/bin/env bash
# Full-mesh network test: ping latency + iperf3 throughput between every pair
# of hosts, over both the wired LAN switch and the Wi-Fi LAN.
#
# Requires: iperf3 installed on every host, passwordless ssh to every peer.

set -u

# ────────────────────────────────────────────────────────────────────────────
# CONFIG — edit these
# ────────────────────────────────────────────────────────────────────────────

# Hosts to test. Each entry: ssh_alias,wired_ip,wifi_ip
# Use "-" for an IP that doesn't exist on this host (skipped).
HOSTS=(
  "self,10.10.10.1,10.0.0.10"     # the driver host (use "self" as alias)
  "mini2,10.10.10.2,10.0.0.50"
  "spark,10.10.10.3,10.0.0.40"
)

DURATION=5      # seconds per iperf3 test
BASE_PORT=5300  # unique port per test to avoid collisions

# ────────────────────────────────────────────────────────────────────────────

CSV_OUT="${HOME}/Library/Logs/lan-perf.log"   # macOS path
mkdir -p "$(dirname "$CSV_OUT")"

# Header on first run
[[ ! -f "$CSV_OUT" ]] && printf 'timestamp,src,dst,path,rtt_ms,throughput_mbit\n' > "$CSV_OUT"

run_remote_iperf_server() {
  local host="$1" port="$2"
  if [[ "$host" == "self" ]]; then
    iperf3 -s -1 -p "$port" >/dev/null 2>&1 &
  else
    ssh -f -o BatchMode=yes "$host" "iperf3 -s -1 -p $port >/dev/null 2>&1"
  fi
}

run_client() {
  local src_host="$1" dst_ip="$2" port="$3"
  local cmd="iperf3 -c $dst_ip -p $port -t $DURATION -f m"
  if [[ "$src_host" == "self" ]]; then
    eval "$cmd" 2>/dev/null
  else
    ssh -n -o BatchMode=yes "$src_host" "$cmd" 2>/dev/null
  fi
}

throughput_mbit() {
  # Parse iperf3 receiver line for sender throughput in Mbit/s
  awk '/receiver/ {print $7; exit}' <<<"$1"
}

ping_one() {
  local src_host="$1" dst_ip="$2"
  local cmd="ping -c 2 -W 1 $dst_ip"
  if [[ "$src_host" == "self" ]]; then
    eval "$cmd" 2>/dev/null
  else
    ssh -n -o BatchMode=yes "$src_host" "$cmd" 2>/dev/null
  fi | awk -F'/' '/^round-trip|^rtt/ {print $5; exit}'
}

stamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

port=$BASE_PORT
for src_entry in "${HOSTS[@]}"; do
  IFS=',' read -r src_host src_wired src_wifi <<<"$src_entry"
  for dst_entry in "${HOSTS[@]}"; do
    IFS=',' read -r dst_host dst_wired dst_wifi <<<"$dst_entry"
    [[ "$src_host" == "$dst_host" ]] && continue

    for path in wired wifi; do
      if [[ "$path" == "wired" ]]; then
        dst_ip="$dst_wired"
      else
        dst_ip="$dst_wifi"
      fi
      [[ "$dst_ip" == "-" ]] && continue

      port=$((port+1))
      run_remote_iperf_server "$dst_host" "$port"
      sleep 1
      result=$(run_client "$src_host" "$dst_ip" "$port")
      mbit=$(throughput_mbit "$result")
      rtt=$(ping_one "$src_host" "$dst_ip")
      printf '%-12s -> %-12s %-5s  %-6s ms  %-6s Mbit/s\n' \
        "$src_host" "$dst_host" "$path" "${rtt:-?}" "${mbit:-?}"
      printf '%s,%s,%s,%s,%s,%s\n' \
        "$(stamp)" "$src_host" "$dst_host" "$path" "${rtt:-}" "${mbit:-}" >> "$CSV_OUT"
    done
  done
done

echo
echo "CSV appended to: $CSV_OUT"

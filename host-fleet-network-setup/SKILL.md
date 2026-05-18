---
name: host-fleet-network-setup
description: "Set up a fast (gigabit) local LAN between Mac and Linux hosts using a standalone unmanaged switch, without breaking internet on any of them. Covers the macOS network-service-order trap that kills DNS when an Ethernet port has no uplink, static-IP assignment patterns for macOS (networksetup) and Linux (NetworkManager with never-default), Application Firewall whitelisting so cross-host tools like iperf3 can listen, and full-mesh speed validation. Use when: building a small home/office lab that wants <1 ms hop-to-hop without paying for a managed switch. NOT for: anything involving DHCP, VLANs, or more than ~5 hosts."
metadata: { "openclaw": { "emoji": "🌐" } }
---

# Host Fleet Network Setup

Get 940 Mbit/s line-rate gigabit between a small set of Macs and Linux boxes
on a standalone unmanaged switch — without breaking internet on any of them.

This skill exists because the **default macOS network priority ordering breaks
internet** the moment you plug a peer-only Ethernet into a switch that has no
uplink to a router. Diagnosis takes longer than the fix.

## Symptoms This Skill Solves

- "I plugged the switch in to share files between my Macs and now Safari can't
  load anything"
- "My peer hosts can reach each other over the switch but I'd rather they used
  the fast switch path, not Wi-Fi, when copying large files"
- "I want to ping every host from every host to confirm the LAN is healthy,
  but pings to one of the Macs always time out"
- "iperf3 server says it's listening but the client can't connect — no
  firewall is enabled, right?"

## When to Use

✅ Use this skill when:

- 2–5 hosts (any mix of macOS + Linux) plugged into one unmanaged switch
- The switch has no router / DHCP server / uplink (it's just for LAN traffic)
- Hosts already have Wi-Fi to a separate router for their internet
- You want sub-millisecond hop latency and ~940 Mbit/s sustained throughput

❌ Don't use when:

- The switch is acting as your primary router (use the router's setup instead)
- You need DHCP on the switch subnet (configure a tiny dnsmasq on the
  driver host or use a managed switch with a DHCP-enabled VLAN)
- You're building real datacenter networking (use Ansible, link aggregation,
  VLANs)

## The Five Steps

### Step 1 — Reorder macOS network services (Wi-Fi above Ethernet)

This is the one that bites. macOS picks the **primary service** (default route
+ DNS source) from the top of `networksetup -listnetworkserviceorder`, not
based on which one has a working route. If Ethernet is #1 and the switch is
plugged in but has no uplink to a router, you get a dead default route and
DNS fails everywhere.

```sh
# Check current order
networksetup -listnetworkserviceorder | grep -E '^\('

# Fix: Wi-Fi first
sudo networksetup -ordernetworkservices "Wi-Fi" "Ethernet" "Thunderbolt Bridge"
```

Run on every Mac (driver + peers). Linux is unaffected — it picks the default
route by metric, not by service order.

### Step 2 — Assign static IPs on a dedicated subnet

Pick a subnet that's clearly **not** your house Wi-Fi (avoid `10.0.0.0/24`,
`192.168.1.0/24`). Examples below use `10.10.10.0/24` with `.1, .2, .3` for
three hosts.

**On each Mac:** static IP with router = self (the trick that keeps macOS
happy without a real gateway):

```sh
sudo networksetup -setmanual "Ethernet" 10.10.10.X 255.255.255.0 10.10.10.X
```

(Use a different `X` per host; setting router to the host's own IP is the
canonical way to tell macOS "yes I'm on this subnet, no there's no gateway.")

**On each Linux peer:** create a NetworkManager profile bound by interface
name, with `ipv4.never-default yes` so it never claims the default route:

```sh
sudo nmcli c add type ethernet \
  con-name lan-switch ifname enX0 \
  ipv4.method manual ipv4.addresses 10.10.10.X/24 \
  ipv4.never-default yes ipv6.method ignore \
  connection.autoconnect yes
sudo nmcli c up lan-switch
```

`never-default true` is the equivalent of macOS's "Wi-Fi above Ethernet" — it
tells the kernel that this link must not provide the default route.

### Step 3 — Open the macOS Application Firewall (or whitelist binaries)

Default macOS firewall behavior **silently drops** inbound traffic to any
binary not in its allow list. Stealth mode additionally drops ICMP, so pings
fail with no error.

If the host is on a trusted LAN (perimeter is your router):

```sh
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode off
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
```

If you want to keep the firewall on but allow specific tools:

```sh
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/iperf3
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /opt/homebrew/bin/iperf3
```

Repeat for any binary that needs to accept inbound (file sharing, dev servers,
etc.).

### Step 4 — Validate with a full mesh ping + iperf3

Use `references/mesh-test.sh` (templated). It expects passwordless SSH to
every peer and `iperf3` installed everywhere.

Expected wired (switch path):
```
laptop ↔ mini2  : ~940 Mbit/s
laptop ↔ spark  : ~940 Mbit/s
mini2  ↔ spark  : ~940 Mbit/s
```

Expected Wi-Fi (same hosts, via 10.0.0.x addresses):
```
50–170 Mbit/s — varies; both-on-AP airtime is the worst case
```

If wired ↔ pairs are dropping below ~900 Mbit/s, suspect:

- Cable not Cat5e or better (will negotiate to 100baseTX silently)
- Port negotiated at 100Mbit (`ifconfig en0` shows `media:` — should be
  `1000baseT <full-duplex>`)
- Switch is congested by another talker

### Step 5 — Optional: capture results in a network log

Record per-pair throughput somewhere durable (`~/Library/Logs/lan-perf.log`)
so you can detect regressions next time you "swear it was faster." The mesh
script appends in CSV.

## Gotchas Worth Knowing

### `networksetup -setmanual` and the router argument

The `router` argument is **required** by the command but **doesn't** install a
default route when this service is not the primary. Setting it to the host's
own IP (e.g. `10.10.10.2`) is the cleanest way to say "directly attached, no
gateway" without confusing macOS — you still get the `10.10.10.0/24` directly-
connected route but no `0.0.0.0/0` entry pointing at a dead address.

### `ipv4.never-default` is the magic flag on Linux

Without `never-default true`, NetworkManager will happily install a default
route via the switch interface with metric ≈100, which beats Wi-Fi (metric
600) and kills internet — same symptom as the macOS service-order trap, but
caused by route metric instead of service order.

### Application Firewall stealth mode silently drops ICMP

You can have a perfectly working TCP service (SSH responds, iperf3 succeeds)
but pings fail. People then conclude "the host is unreachable" and burn time
debugging the wrong layer. Always test with both `ping` AND
`nc -vz host port` before drawing conclusions about reachability.

### Local-only Docker images "fail" to pull (and that's fine)

If you run our `weekly-infra-maintenance` skill against a host that builds
docker images locally (not pushed to any registry), those `docker pull`s will
fail with "repository does not exist." Expected; weekly-maintenance's exit
code intentionally doesn't count that as a hard failure.

## Files

- `references/mesh-test.sh` — full-mesh ping + iperf3 throughput sweep across
  a configured peer list, both wired and Wi-Fi
- `references/static-ip-cheatsheet.md` — copy-pasteable commands for the
  three-host worked example (macOS driver + macOS peer + Linux peer)

## Related

- [[weekly-infra-maintenance]] — once the network is healthy, schedule the
  cross-host maintenance run.

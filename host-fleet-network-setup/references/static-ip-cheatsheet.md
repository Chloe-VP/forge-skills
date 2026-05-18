# Static-IP cheatsheet (3-host worked example)

Worked example: one macOS driver Mac (`driver`), one macOS peer (`peer-mac`),
one Linux peer (`peer-linux`). All on a standalone unmanaged gigabit switch.
Subnet `10.10.10.0/24`. IPs `.1, .2, .3`.

> ⚠️ Run **Step 1** on every Mac first or you'll lose internet the moment you
> plug the switch in.

## Step 1 — Reorder services (every Mac)

```sh
networksetup -listnetworkserviceorder | grep -E '^\('   # check current
sudo networksetup -ordernetworkservices "Wi-Fi" "Ethernet" "Thunderbolt Bridge"
```

## Step 2 — Static IPs

### Driver Mac (10.10.10.1)
```sh
sudo networksetup -setmanual "Ethernet" 10.10.10.1 255.255.255.0 10.10.10.1
```

### Peer Mac (10.10.10.2)
```sh
sudo networksetup -setmanual "Ethernet" 10.10.10.2 255.255.255.0 10.10.10.2
```

### Peer Linux (10.10.10.3)

Find your wired interface name first (`ip -br link` — look for the cable that's
plugged into the switch with state UP):

```sh
ip -br link
# e.g. enP7s7 UP 4c:bb:47:80:2f:8b <BROADCAST,MULTICAST,UP,LOWER_UP>
```

Then create a never-default NetworkManager profile bound to that interface:

```sh
sudo nmcli c add type ethernet \
  con-name lan-switch ifname enP7s7 \
  ipv4.method manual ipv4.addresses 10.10.10.3/24 \
  ipv4.never-default yes ipv6.method ignore \
  connection.autoconnect yes
sudo nmcli c up lan-switch
```

## Step 3 — Firewall

If the LAN is trusted (your router does perimeter), disable the macOS
Application Firewall on the peer Mac so cross-host services and pings just
work:

```sh
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate off
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode off
```

If you'd rather keep the firewall on, whitelist each tool that needs to
accept inbound:

```sh
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /opt/homebrew/bin/iperf3
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /opt/homebrew/bin/iperf3
```

## Step 4 — Validate

Quick mesh:

```sh
# from driver
ping -c 2 10.10.10.2   # peer-mac
ping -c 2 10.10.10.3   # peer-linux

ssh peer-mac   "ping -c 2 10.10.10.3"   # peer-mac -> peer-linux
ssh peer-linux "ping -c 2 10.10.10.2"   # peer-linux -> peer-mac
```

Expect <1 ms across the switch. If pings fail TO a Mac but TCP works (`nc -vz
10.10.10.X 22`), the firewall stealth mode is still on — see Step 3.

Throughput:

```sh
# on the destination
iperf3 -s -1

# on the source
iperf3 -c 10.10.10.X -t 5 -f m
```

Expect ~940 Mbit/s line-rate. Anything under ~900 Mbit/s, check `ifconfig` /
`ip link` for negotiated media (`1000baseT <full-duplex>`).

## Step 5 — Verify internet still works (every Mac)

```sh
curl -s -o /dev/null -w "%{http_code}\n" https://api.ipify.org
route -n get default | grep -E 'gateway|interface'   # should be Wi-Fi (en1 or wlanX)
```

If `interface:` shows `en0` (Ethernet) instead of Wi-Fi, Step 1 didn't take —
re-run, then `sudo killall -HUP mDNSResponder` to flush.

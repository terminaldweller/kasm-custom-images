#!/bin/sh
set -eu

TUN_IF="${XRAY_TUN_IF:-xray0}"
UPLINK_IF="${XRAY_UPLINK_IF:-eth0}"

LAN_IP="${XRAY_LAN_IP:-172.16.70.66}"
LAN_SUBNET="${XRAY_LAN_SUBNET:-172.16.70.0/24}"
ROUTE_TABLE="${XRAY_ROUTE_TABLE:-1001}"

echo "Starting Xray..."

/usr/local/bin/xray "$@" &
XRAY_PID=$!

stop_xray() {
    echo "Stopping Xray..."
    kill -TERM "$XRAY_PID" 2>/dev/null || true
    wait "$XRAY_PID" 2>/dev/null || true
}

trap stop_xray INT TERM

echo "Waiting for ${TUN_IF}..."

attempt=0
while ! ip link show "$TUN_IF" >/dev/null 2>&1; do
    if ! kill -0 "$XRAY_PID" 2>/dev/null; then
        echo "Xray exited before creating ${TUN_IF}" >&2
        wait "$XRAY_PID"
        exit $?
    fi

    attempt=$((attempt + 1))

    if [ "$attempt" -ge 100 ]; then
        echo "Timed out waiting for ${TUN_IF}" >&2
        stop_xray
        exit 1
    fi

    sleep 0.1
done

echo "Configuring routing through ${TUN_IF}..."

# Make sure Docker actually assigned the address we expect.
if ! ip -o -4 addr show dev "$UPLINK_IF" |
    awk '{print $4}' |
    cut -d/ -f1 |
    grep -Fxq "$LAN_IP"
then
    echo "ERROR: ${LAN_IP} is not assigned to ${UPLINK_IF}" >&2
    echo "Addresses on ${UPLINK_IF}:" >&2
    ip -4 addr show dev "$UPLINK_IF" >&2
    stop_xray
    exit 1
fi

sysctl -qw net.ipv4.ip_forward=1
sysctl -qw net.ipv4.conf.all.rp_filter=0
sysctl -qw net.ipv4.conf.default.rp_filter=0
sysctl -qw "net.ipv4.conf.${UPLINK_IF}.rp_filter=0"
sysctl -qw "net.ipv4.conf.${TUN_IF}.rp_filter=0"

#
# Routing table 1001
#

# Keep the Docker/downstream subnet reachable through the normal uplink.
#
# Do NOT specify "src $LAN_IP" here. The kernel can choose the locally
# assigned source address itself, and forcing prefsrc was causing:
#
#     Error: Invalid prefsrc address.
#
ip route replace \
    "$LAN_SUBNET" \
    dev "$UPLINK_IF" \
    table "$ROUTE_TABLE"

# Everything else using table 1001 goes through Xray.
ip route replace \
    default \
    dev "$TUN_IF" \
    table "$ROUTE_TABLE"

#
# Policy rules
#

# Remove stale rules if this script is run again in the same namespace.
while ip rule del pref 100 2>/dev/null; do :; done
while ip rule del pref 200 2>/dev/null; do :; done

# Xray's own outbound REALITY connection MUST use Docker's normal
# routing table, otherwise Xray would recursively route itself into xray0.
ip rule add \
    pref 100 \
    from "${LAN_IP}/32" \
    lookup main

# Traffic originating from downstream/Kasm containers goes through Xray.
ip rule add \
    pref 200 \
    from "$LAN_SUBNET" \
    lookup "$ROUTE_TABLE"

echo "Policy routing configured:"
echo
ip rule show
echo
ip route show table "$ROUTE_TABLE"

wait "$XRAY_PID"

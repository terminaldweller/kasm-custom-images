#!/bin/sh
set -eu

TUN_IF="${XRAY_TUN_IF:-xray0}"
UPLINK_IF="${XRAY_UPLINK_IF:-eth0}"

LAN_IP="${XRAY_LAN_IP:-177.44.0.66}"
LAN_SUBNET="${XRAY_LAN_SUBNET:-177.44.0.0/24}"
ROUTE_TABLE="${XRAY_ROUTE_TABLE:-1001}"

echo "Starting Xray..."

# Preserve the arguments supplied by CMD or Docker Compose.
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

sysctl -qw net.ipv4.ip_forward=1
sysctl -qw net.ipv4.conf.all.rp_filter=0
sysctl -qw net.ipv4.conf.default.rp_filter=0
sysctl -qw "net.ipv4.conf.${UPLINK_IF}.rp_filter=0"
sysctl -qw "net.ipv4.conf.${TUN_IF}.rp_filter=0"

# Downstream containers must remain reachable through the Docker bridge.
ip route replace \
    "$LAN_SUBNET" \
    dev "$UPLINK_IF" \
    src "$LAN_IP" \
    table "$ROUTE_TABLE"

# Send downstream traffic into Xray's TUN interface.
ip route replace \
    default \
    dev "$TUN_IF" \
    table "$ROUTE_TABLE"

# Remove stale copies if Docker restarted only the process while preserving
# the network namespace.
while ip rule del pref 100 2>/dev/null; do :; done
while ip rule del pref 200 2>/dev/null; do :; done

# Keep Xray's own REALITY connection on the ordinary Docker default route.
ip rule add \
    pref 100 \
    from "${LAN_IP}/32" \
    lookup main

# Route traffic originating from Kasm/downstream containers into xray0.
ip rule add \
    pref 200 \
    from "$LAN_SUBNET" \
    lookup "$ROUTE_TABLE"

echo "Policy routing configured:"
ip rule show
ip route show table "$ROUTE_TABLE"

wait "$XRAY_PID"

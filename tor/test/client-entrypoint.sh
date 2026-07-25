#!/bin/sh

apk update && apk add nftables iproute2 curl

ip route del default
ip route add default via 172.50.0.15

/bin/sleep infinity

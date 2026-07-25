#!/bin/sh
set -xe

# apk update && apk add tor nftables iproute2

nft add table ip tor
nft list tables
nft 'add chain ip tor prerouting {
  type nat hook prerouting priority dstnat;
  policy accept;
}'

nft add rule ip tor prerouting \
  ip saddr 172.50.0.0/24 \
  ip daddr != 172.50.0.0/24 \
  meta l4proto tcp \
  counter \
  redirect to :9040

nft add rule ip tor prerouting \
  ip saddr 172.50.0.0/24 \
  udp dport 53 \
  counter \
  redirect to :5353

nft add table ip filter
nft 'add chain ip filter forward {
  type filter hook forward priority filter;
  policy accept;
}'

nft add rule ip filter forward \
  ip saddr 172.50.0.0/24 \
  reject

tor -f /etc/tor/torrc

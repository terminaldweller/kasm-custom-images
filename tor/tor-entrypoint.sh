#!/bin/sh
set -xe

# run on the docker host
# modprobe nf_nat nft_nat nft_reject nft_reject_ipv4 nft_reject_ipv6

# apk update && apk add tor nftables iproute2

nft add table ip tor
nft list tables
nft 'add chain ip tor prerouting {
  type nat hook prerouting priority dstnat;
  policy accept;
}'

nft add rule ip tor prerouting \
  ip saddr 172.50.0.0/24 \
  udp dport 53 \
  counter \
  dnat to 172.50.0.15:5353

nft add rule ip tor prerouting \
  ip saddr 172.50.0.0/24 \
  tcp dport 53 \
  counter \
  dnat to 172.50.0.15:5353

nft add rule ip tor prerouting \
  ip saddr 172.50.0.0/24 \
  ip daddr != 172.50.0.0/24 \
  meta l4proto tcp \
  counter \
  dnat to 172.50.0.15:9040

nft add table ip filter
nft 'add chain ip filter forward {
  type filter hook forward priority filter;
  policy accept;
}'

nft add rule ip filter forward \
  ip saddr 172.50.0.0/24 \
  reject

tor -f /etc/tor/torrc

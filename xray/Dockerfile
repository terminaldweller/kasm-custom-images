ARG XRAY_IMAGE=ghcr.io/xtls/xray-core:26.3.23

FROM ${XRAY_IMAGE} AS upstream

FROM alpine:3.22

RUN apk add --no-cache \
    ca-certificates \
    iproute2 \
    procps \
    tzdata

COPY --from=upstream /usr/local/bin/xray /usr/local/bin/xray
COPY --from=upstream /usr/local/share/xray /usr/local/share/xray

COPY xray-entrypoint.sh /usr/local/bin/xray-entrypoint
RUN chmod 0755 \
    /usr/local/bin/xray \
    /usr/local/bin/xray-entrypoint

ENTRYPOINT ["/usr/local/bin/xray-entrypoint"]
CMD ["run", "-config", "/usr/local/etc/xray/config.json"]

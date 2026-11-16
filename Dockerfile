# EMQX MQTT broker for Railway: the official EMQX image plus a small Caddy
# router so the dashboard and MQTT over WebSocket share one HTTPS domain.
FROM caddy:2.11.9@sha256:4e2425f6009577e7c651010f16679c28f7d12df3e7b1914f941a7a3370746b3c AS caddy

FROM emqx/emqx:6.3.3@sha256:54778dba62a5cbcb03ca381c9bceb3d8a87cab9e3da155ed3607d994454df900

# Railway mounts volumes owned by root, so run as root to write /opt/emqx/data.
USER root

COPY --from=caddy /usr/bin/caddy /usr/bin/caddy
COPY Caddyfile /etc/caddy/Caddyfile
COPY start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /usr/local/bin/railway-start.sh

ENV PORT=8080
EXPOSE 8080 1883

ENTRYPOINT ["/usr/local/bin/railway-start.sh"]

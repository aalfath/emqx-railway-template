#!/usr/bin/env bash
# Start script for the EMQX Railway template.
# Runs Caddy (public HTTP on $PORT) and EMQX side by side and stops the
# container when either of them exits, so Railway restarts it.
set -euo pipefail

export PORT="${PORT:-8080}"

# A fixed node name keeps the built-in database (users, rules, settings) in the
# same place on the volume across redeploys. The default uses the container IP,
# which changes on every deploy and would start from an empty database.
export EMQX_NODE__NAME="${EMQX_NODE__NAME:-emqx@127.0.0.1}"
export EMQX_DASHBOARD__DEFAULT_USERNAME="${EMQX_DASHBOARD__DEFAULT_USERNAME:-admin}"
# Listen for MQTT on IPv4 and IPv6, so other services can reach the broker over
# Railway's private network as well as through the TCP proxy.
export EMQX_LISTENERS__TCP__DEFAULT__BIND="${EMQX_LISTENERS__TCP__DEFAULT__BIND:-[::]:1883}"
if [[ -z "${EMQX_DASHBOARD__DEFAULT_PASSWORD:-}" ]]; then
  echo "EMQX_DASHBOARD__DEFAULT_PASSWORD is empty: refusing to start with the default dashboard password." >&2
  exit 1
fi

MQTT_USERNAME="${MQTT_USERNAME:-mqtt}"
if [[ -z "${MQTT_PASSWORD:-}" ]]; then
  echo "MQTT_PASSWORD is empty: refusing to start an MQTT broker without a password." >&2
  exit 1
fi

mkdir -p /opt/emqx/data /opt/emqx/log

# MQTT clients must log in. The first user comes from MQTT_USERNAME and
# MQTT_PASSWORD and is imported into the built-in database on boot (an
# existing user is left as it is). Add more users in the dashboard under
# Access Control > Authentication. The chain lives in base.hocon, so changes
# made in the dashboard win over these defaults and survive redeploys.
BOOTSTRAP=/opt/emqx/etc/railway-mqtt-users.csv
umask 077
printf 'user_id,password,is_superuser\n%s,%s,false\n' "$MQTT_USERNAME" "$MQTT_PASSWORD" > "$BOOTSTRAP"
umask 022
if ! grep -q 'railway-mqtt-users.csv' /opt/emqx/etc/base.hocon; then
  cat >> /opt/emqx/etc/base.hocon <<HOCON

## Added by the Railway template: password login for MQTT clients.
authentication = [
  {
    mechanism = password_based
    backend = built_in_database
    user_id_type = username
    password_hash_algorithm { name = sha256, salt_position = suffix }
    bootstrap_file = "${BOOTSTRAP}"
    bootstrap_type = plain
  }
]

## Added by the Railway template: keep retained messages on the volume, so
## they survive redeploys (EMQX keeps them in memory by default).
retainer.backend.storage_type = disc
HOCON
fi

caddy run --config /etc/caddy/Caddyfile --adapter caddyfile &
caddy_pid=$!

/usr/bin/docker-entrypoint.sh /opt/emqx/bin/emqx foreground &
emqx_pid=$!

stop() {
  kill -TERM "$emqx_pid" "$caddy_pid" 2>/dev/null || true
}
trap stop TERM INT

set +e
wait -n "$emqx_pid" "$caddy_pid"
code=$?
stop
wait
exit "$code"

# EMQX on Railway

A one-click [Railway](https://railway.com) template for [EMQX](https://www.emqx.com/), the MQTT broker for IoT devices and apps.

## What it deploys

One service, built from this repo's `Dockerfile`:

- **EMQX 6.3.3**, from the official image `emqx/emqx:6.3.3`, pinned by digest. Single node.
- **Caddy 2.11.9** in the same container, listening on Railway's `PORT`:
  - `https://YOUR-DOMAIN/` is the EMQX dashboard (user `admin`).
  - `wss://YOUR-DOMAIN/mqtt` is MQTT over WebSocket.
- **A TCP proxy on port 1883** for plain MQTT (`mqtt://HOST:PORT`, host and port shown in the service's Networking settings).
- **A volume at `/opt/emqx/data`** for the built-in database: MQTT users, rules, retained settings and dashboard changes survive redeploys.

## Variables

| Variable | Default | What it is |
|---|---|---|
| `EMQX_DASHBOARD__DEFAULT_PASSWORD` | generated | Password of the dashboard user `admin`. Used only when the dashboard user is first created; change it later in the dashboard. |
| `MQTT_USERNAME` | `mqtt` | First MQTT user, created on first boot. |
| `MQTT_PASSWORD` | generated | Password of that MQTT user. |
| `EMQX_NODE__COOKIE` | generated | Erlang node cookie. |
| `PORT` | `8080` | Port Caddy listens on for the Railway domain. |

Anonymous MQTT logins are refused. Add more MQTT users in the dashboard under **Access Control → Authentication**. The first user is imported only when it doesn't exist yet, so changing `MQTT_PASSWORD` later doesn't change an existing user's password: change it in the dashboard.

The start script refuses to start when the dashboard or MQTT password is empty.

## Connecting

- MQTT over TCP: `mqtt://mqtt:MQTT_PASSWORD@RAILWAY_TCP_PROXY_DOMAIN:RAILWAY_TCP_PROXY_PORT`
- MQTT over WebSocket (TLS): `wss://YOUR-DOMAIN:443/mqtt`
- From another service in the same Railway project: `mqtt://emqx.railway.internal:1883` (the broker listens on IPv4 and IPv6).

TLS on the TCP proxy (port 8883) isn't set up: Railway's TCP proxy passes raw TCP, so clients that need TLS should use `wss://` or bring their own certificates.

## License

EMQX 5.9 and later is released by EMQ under the Business Source License 1.1. It includes a Community License for free production use of **a single node** in your own environment; clustering, or offering EMQX to third parties as a hosted service, needs a commercial license from EMQ. See the [EMQX licensing FAQ](https://www.emqx.com/en/content/license-faq). This repo's wrapper files (Dockerfile, start script, Caddyfile) are MIT.

## Updates

The EMQX and Caddy versions are pinned in the `Dockerfile`. When this repo's `main` branch gets a new version, Railway shows an "update available" notice to everyone who deployed the template, and each deployer chooses when to apply it. Read `CHANGELOG.md` before you update: EMQX data on the volume is migrated forward on start and can't be downgraded.

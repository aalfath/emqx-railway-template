# Changelog

Each entry is one version of this Railway template. Breaking changes come first.

## 6.3.3-2 (2026-11-16)

- README: Deploy on Railway button for the published template (`emqx-1`). No change to the service.

## 6.3.3-1 (2026-11-16)

- First release: EMQX 6.3.3 (`emqx/emqx:6.3.3@sha256:54778dba62a5cbcb03ca381c9bceb3d8a87cab9e3da155ed3607d994454df900`), single node.
- Caddy 2.11.9 routes the Railway domain: `/mqtt` to MQTT over WebSocket, everything else to the dashboard.
- MQTT clients must log in. The first user comes from `MQTT_USERNAME` / `MQTT_PASSWORD`.
- Data (built-in database, users, rules, settings, retained messages) lives on a volume at `/opt/emqx/data`.

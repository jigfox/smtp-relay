# smtp-relay

Postfix that relays all mail through one authenticated upstream SMTP server,
published as `ghcr.io/jigfox/smtp-relay` (`linux/amd64`, `linux/arm64`).

Every push to `main` publishes `:latest` and `:sha-<commit>`; a `vX.Y.Z` tag
also publishes `:X.Y.Z` and `:X.Y`.

## Environment variables

| Variable | Required | Description |
| --- | --- | --- |
| `RELAY_HOST` | yes | Upstream SMTP server |
| `RELAY_PORT` | yes | Upstream port (e.g. `587`) |
| `RELAY_USER` | yes | Upstream SASL user |
| `RELAY_PASS` | yes | Upstream SASL password |
| `RELAY_NAME` | no | `myhostname` (default `localhost`) |
| `RELAY_NETS` | no | Clients allowed to relay (default `127.0.0.0/8 10.0.0.0/8 192.168.0.0/16`) |
| `RELAY_ALLOWED_SENDERS` | no | Comma-separated sender addresses or domains; when set, every other sender is rejected |
| `RELAY_SENDER_ACCESS_FILE` | no | Where the sender list is written (default `/etc/postfix/sender_access`) |
| `RELAY_SSL_PATH` | no | Directory with `server.crt` and `server.key`; enables TLS for clients |
| `RELAY_ENABLE_START_TLS` | no | With `RELAY_SSL_PATH`: also listen for submission on 587 |
| `RELAY_ENABLE_SMTPS` | no | With `RELAY_SSL_PATH`: also listen for SMTPS on 465 |

Port 25 is always open. Mail logs go to stdout.

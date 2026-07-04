## Dev

Provisions PHP + Swoole + PostgreSQL + Redis + Node and the edge web server.
The edge proxy is **OpenResty** (nginx + Lua) — plain nginx for primary domains,
plus the Lua module used for per-SNI custom-domain TLS. A dev self-signed cert is
generated automatically.

```bash
sudo rm -f server.sh && \
sudo wget --no-cache --no-cookies https://raw.githubusercontent.com/fluffy-space/win-ubuntu-vbox/main/scripts/server.sh && \
sudo bash server.sh
```

## Prod

Same install; for a public domain replace the dev self-signed cert with a real
one (`certbot --nginx`, or acme.sh). Pass `--email` to record an ACME contact for
renewal notices (DNS must point at this host and ports 80/443 must be open):

```bash
sudo rm -f server.sh && \
sudo wget --no-cache --no-cookies https://raw.githubusercontent.com/fluffy-space/win-ubuntu-vbox/main/scripts/server.sh && \
sudo bash server.sh --prod --email you@example.com
```

## Options

| Flag | Default | Meaning |
|---|---|---|
| `--prod` | dev | Use `php.ini-production` |
| `--email <addr>` | _(none)_ | ACME account email for a real cert (certbot/acme on a public prod domain) |

After the script finishes, generate a per-domain site config with
`sudo php fluffy nginx <domain>`.

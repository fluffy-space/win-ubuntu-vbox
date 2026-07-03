## Dev

Provisions PHP + Swoole + PostgreSQL + Redis + Node and the edge web server.
The web server defaults to **Caddy** (automatic TLS); pass `--webserver nginx`
to use NGINX instead.

```bash
sudo rm -f server.sh && \
sudo wget --no-cache --no-cookies https://raw.githubusercontent.com/fluffy-space/win-ubuntu-vbox/main/scripts/server.sh && \
sudo bash server.sh
```

NGINX instead of Caddy:

```bash
sudo bash server.sh --webserver nginx
```

## Prod

Caddy issues real Let's Encrypt certs in prod — pass `--email` so you get
renewal notices (DNS must point at this host and ports 80/443 must be open):

```bash
sudo rm -f server.sh && \
sudo wget --no-cache --no-cookies https://raw.githubusercontent.com/fluffy-space/win-ubuntu-vbox/main/scripts/server.sh && \
sudo bash server.sh --prod --email you@example.com
```

## Options

| Flag | Default | Meaning |
|---|---|---|
| `--prod` | dev | Use `php.ini-production` and real Let's Encrypt TLS (Caddy) |
| `--webserver caddy\|nginx` | `caddy` | Edge reverse proxy / TLS termination |
| `--email <addr>` | _(none)_ | ACME account email for Let's Encrypt renewal notices (prod Caddy) |

After the script finishes, generate a per-domain site config with
`sudo php fluffy caddy <domain>` (Caddy) or `sudo php fluffy nginx <domain>` (NGINX).

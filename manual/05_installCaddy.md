# Install Caddy

[Go Back](./../README.md)

Caddy is the edge reverse proxy in front of the Swoole app (an alternative to
[NGINX](./05_installNginx.md)) that issues and renews TLS certificates
automatically. This sets up the Caddy infrastructure only — per-domain site
files are generated later with `sudo php fluffy caddy <domain>`.

```bash
# Official Caddy apt repo (signed)
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https ca-certificates curl gnupg
curl -1fsSL 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
  | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1fsSL 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
  | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install -y caddy

# Firewall: 80 (ACME challenge + HTTP->HTTPS redirect) and 443 (TLS)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Managed main Caddyfile that imports per-domain site files
sudo mkdir -p /etc/caddy/sites
sudo tee /etc/caddy/Caddyfile >/dev/null <<'CADDYFILE'
{
	grace_period 30s
	admin 127.0.0.1:2019
}

import /etc/caddy/sites/*.caddy
CADDYFILE

sudo caddy validate --config /etc/caddy/Caddyfile
sudo systemctl enable --now caddy
systemctl status caddy
```

On a dev VM, Caddy issues self-signed certs from its **internal CA** — trust it
once in the guest so browsers accept them:

```bash
sudo caddy trust
```

For **production** (real Let's Encrypt certs) add your ACME email to the global
options block so you get renewal notices — DNS must point at this host and
ports 80/443 must be reachable:

```caddyfile
{
	email you@example.com
	grace_period 30s
	admin 127.0.0.1:2019
}

import /etc/caddy/sites/*.caddy
```

[Go Back](./../README.md)

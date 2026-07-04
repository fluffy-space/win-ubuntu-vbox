# Install OpenResty (nginx + Lua)

[Go Back](./../README.md)

OpenResty is plain nginx plus LuaJIT and the `lua-resty-*` bundle — nginx for
primary domains, with the Lua module used for per-SNI custom-domain TLS. The
`server.sh` provisioner does all of this; the manual steps:

```bash
# 1. OpenResty apt repo (signed) + package
sudo apt install -y ca-certificates curl gnupg lsb-release openssl
curl -1fsSL 'https://openresty.org/package/pubkey.gpg' | sudo gpg --dearmor -o /usr/share/keyrings/openresty.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/openresty.gpg] http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
  | sudo tee /etc/apt/sources.list.d/openresty.list
sudo apt update
sudo apt install -y openresty

# 2. /etc/nginx layout (so `php fluffy nginx <domain>` works) + firewall
sudo mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled /etc/nginx/conf.d
sudo ufw allow 80/tcp && sudo ufw allow 443/tcp

# 3. dev self-signed cert
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -subj "/CN=localhost" \
  -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

sudo /usr/local/openresty/bin/openresty -t
sudo systemctl enable --now openresty
```

Fluffy ships a complete, idempotent installer that also drops the shared tuning
(upstream keepalive map + TLS session cache) and the managed main config:

```bash
sudo bash vendor/fluffy-space/fluffy/scripts/install-openresty-ubuntu24.sh
```

Then generate a per-domain site config:

```bash
sudo php fluffy nginx your.domain.com
```

[Go Back](./../README.md)

#!/bin/bash
# Exit on error, treat unset vars as errors, fail a pipeline if any stage fails.
set -euo pipefail

echo "Running server set up"

usage() {
    cat <<'USAGE'
Usage: sudo bash server.sh [options]

  --prod                 Production mode: php.ini-production.
  --email <address>      ACME account email for a real cert (certbot/acme on a public prod domain).
  --help                 Show this help and exit.

The edge proxy is OpenResty (nginx + Lua) — no --webserver choice.
Versions can be overridden via env: PHP_VER, SWOOLE_VER, NODE_MAJOR.
USAGE
}

## Reading arguments
PROD=0
ACME_EMAIL="${ACME_EMAIL:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prod)
            echo "Using production mode."
            PROD=1
            shift
            ;;
        --email)
            # ACME account email for a real cert (certbot/acme on a public prod domain).
            ACME_EMAIL="$2"
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

printf "Argument prod is %s\n" "$PROD"

## Versions — bump these to upgrade (overridable via env; see TODO.md)
PHP_VER="${PHP_VER:-8.5.7}"
SWOOLE_VER="${SWOOLE_VER:-6.2.1}"
NODE_MAJOR="${NODE_MAJOR:-22}"
PHP_MAJOR="${PHP_VER:0:1}"

apt update -y

## Installing SSH
apt install openssh-server -y

## Creating workspace directory
echo "Creating /workspace"
mkdir -p /workspace
cd /workspace

# Own it by the login user (when invoked via sudo) instead of world-writable 777.
if [[ -n "${SUDO_USER:-}" ]]; then
    chown -R "$SUDO_USER":"$SUDO_USER" /workspace
fi
chmod -R 755 /workspace

## Installing PHP

rm -f /usr/local/lib/php.ini

echo "Installing PHP $PHP_VER"
apt install -y pkg-config build-essential autoconf bison re2c postgresql postgresql-contrib libpq-dev \
               libcurl4-openssl-dev openssl libssl-dev libxml2-dev libsqlite3-dev zlib1g-dev libonig-dev libssh2-1-dev liburing-dev
wget "https://github.com/php/php-src/archive/php-$PHP_VER.tar.gz"
tar --extract --gzip --file "php-$PHP_VER.tar.gz"
rm -f "php-$PHP_VER.tar.gz"
cd "php-src-php-$PHP_VER"
./buildconf --force
## --prefix="/usr/local/php${PHP_MAJOR}" - use for multiple versions
## --with-config-file-path="/etc/php${PHP_MAJOR}/cli" \
## --with-config-file-scan-dir="/etc/php${PHP_MAJOR}/cli/conf.d/" \
./configure \
--enable-zts --with-openssl --with-zlib --enable-bcmath --with-curl --enable-mbstring --with-pdo-mysql --with-pdo-pgsql --with-pgsql --enable-sockets --enable-soap
make -j"$(nproc)"
make install

PHP_INSTALLED_VERSION=$(php -r "echo PHP_VERSION;" 2>/dev/null || echo "none")

if [[ "$PHP_INSTALLED_VERSION" != "$PHP_VER" ]]; then
    echo "PHP $PHP_VER installation failed."
    exit 1;
else
    echo "PHP $PHP_VER successfully installed."
fi

if [[ "$PROD" -eq 1 ]]; then
    echo "Using php.ini production"
    cp ./php.ini-production /usr/local/lib/php.ini
else
    echo "Using php.ini development"
    cp ./php.ini-development /usr/local/lib/php.ini
fi

apt install -y composer php-pear
pecl install inotify
printf "\n" | pecl install redis
echo 'extension=inotify.so' | tee -a /usr/local/lib/php.ini
echo 'extension=redis.so' | tee -a /usr/local/lib/php.ini
php -v

## Install Swoole

echo "Installing Swoole $SWOOLE_VER"
apt-get install -y  libc-ares-dev postgresql postgresql-contrib libpq-dev
wget "https://github.com/swoole/swoole-src/archive/refs/tags/v$SWOOLE_VER.tar.gz"
tar --extract --gzip --file "v$SWOOLE_VER.tar.gz"
rm -f "v$SWOOLE_VER.tar.gz"
cd "swoole-src-$SWOOLE_VER"
phpize && \
./configure \
--enable-openssl --enable-swoole-curl --enable-cares --enable-swoole-pgsql --enable-swoole-thread --enable-swoole-ftp --with-swoole-ssh2
make -j"$(nproc)"
make install

echo 'extension=swoole.so' | tee -a /usr/local/lib/php.ini

## Web server (edge reverse proxy + TLS): OpenResty (nginx + Lua)
##
## OpenResty = nginx + LuaJIT + lua-resty-* — plain nginx for primary domains,
## with the Lua module we need for per-SNI custom-domain TLS. Installs the apt
## repo + package, the /etc/nginx layout (so `php fluffy nginx <domain>` works),
## the shared http-context tuning (upstream keepalive map + TLS session cache),
## a dev self-signed cert, and the firewall. Per-domain site files are generated
## later by:  sudo php fluffy nginx <domain>
##
## (Fluffy ships the same as a standalone, more thorough installer:
##  vendor/fluffy-space/fluffy/scripts/install-openresty-ubuntu24.sh)

# Official OpenResty apt repo (signed).
apt install -y ca-certificates curl gnupg lsb-release openssl
curl -1fsSL 'https://openresty.org/package/pubkey.gpg' \
    | gpg --dearmor -o /usr/share/keyrings/openresty.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/openresty.gpg] http://openresty.org/package/ubuntu $(lsb_release -sc) main" \
    | tee /etc/apt/sources.list.d/openresty.list
apt update
apt install -y openresty

# Firewall: 80 (HTTP->HTTPS + ACME) and 443 (TLS).
ufw allow 80/tcp
ufw allow 443/tcp
ufw app list

# /etc/nginx layout wired into OpenResty's main config (NginxBuilder writes here).
mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled /etc/nginx/conf.d

# Shared http-context tuning the per-site template depends on.
tee /etc/nginx/conf.d/00-fluffy-tuning.conf >/dev/null <<'TUNING'
map $http_upgrade $connection_upgrade { default upgrade; '' ''; }
ssl_session_cache   shared:SSL:50m;
ssl_session_timeout 1d;
ssl_session_tickets off;
ssl_protocols       TLSv1.2 TLSv1.3;
resolver 127.0.0.53 ipv6=off valid=30s;
TUNING

tee /usr/local/openresty/nginx/conf/nginx.conf >/dev/null <<'MAIN'
user  www-data;
worker_processes  auto;
worker_rlimit_nofile 65535;
events { worker_connections 16384; multi_accept on; }
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile on; tcp_nopush on; tcp_nodelay on;
    keepalive_timeout 65;
    server_tokens off;
    lua_shared_dict fluffy_tls 16m;
    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
MAIN

# Dev self-signed cert (real cert via certbot/acme for public prod domains).
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -subj "/CN=localhost" \
    -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

/usr/local/openresty/bin/openresty -t
systemctl enable openresty
systemctl restart openresty

## Postgresql

apt update
systemctl start postgresql.service

## Redis

apt install -y redis-server

## Node.js — via NodeSource (Ubuntu's apt Node is old); npm ships with it.

curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
apt install -y nodejs
node -v && npm -v

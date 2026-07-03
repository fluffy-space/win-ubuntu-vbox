#!/bin/bash
# Exit on error, treat unset vars as errors, fail a pipeline if any stage fails.
set -euo pipefail

echo "Running server set up"

usage() {
    cat <<'USAGE'
Usage: sudo bash server.sh [options]

  --prod                 Production mode: php.ini-production + real Let's Encrypt TLS (Caddy).
  --webserver caddy|nginx  Edge reverse proxy / TLS termination. Default: caddy.
  --email <address>      ACME account email for Let's Encrypt renewal notices (prod Caddy).
  --help                 Show this help and exit.

Versions can be overridden via env: PHP_VER, SWOOLE_VER, NODE_MAJOR.
USAGE
}

## Reading arguments
PROD=0
WEBSERVER="${WEBSERVER:-caddy}"   # caddy (default) | nginx
CADDY_EMAIL="${CADDY_EMAIL:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prod)
            echo "Using production mode."
            PROD=1
            shift
            ;;
        --webserver)
            # Edge web server / reverse proxy: caddy (default) or nginx.
            WEBSERVER="$2"
            shift 2
            ;;
        --email)
            # ACME account email for Let's Encrypt (prod TLS renewal notices).
            CADDY_EMAIL="$2"
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

## Web server (edge reverse proxy + TLS): caddy (default) or nginx

if [[ "$WEBSERVER" == "caddy" ]]; then

    ## Caddy — edge reverse proxy + automatic TLS
    ##
    ## Sets up the Caddy infrastructure only: apt repo, package, firewall, and a
    ## managed /etc/caddy/Caddyfile that imports per-domain site files. The site
    ## files themselves are generated later by:  sudo php fluffy caddy <domain>

    # Official Caddy apt repo (signed).
    apt install -y debian-keyring debian-archive-keyring apt-transport-https ca-certificates curl gnupg
    curl -1fsSL 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
        | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1fsSL 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
        | tee /etc/apt/sources.list.d/caddy-stable.list
    apt update
    apt install -y caddy

    # Firewall: Caddy needs 80 (ACME challenge + HTTP->HTTPS redirect) and 443 (TLS).
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw app list

    # Managed main Caddyfile: global options + `import sites/*.caddy`. Per-domain
    # configs drop into /etc/caddy/sites/ (via `php fluffy caddy <domain>`).
    mkdir -p /etc/caddy/sites
    if [[ "$PROD" -eq 1 ]]; then
        # Prod: real Let's Encrypt certs (needs public DNS + reachable 80/443).
        echo "Configuring Caddy for production TLS (email: ${CADDY_EMAIL:-<unset>})"
        tee /etc/caddy/Caddyfile >/dev/null <<CADDYFILE
{
$( [[ -n "$CADDY_EMAIL" ]] && printf '\temail %s\n' "$CADDY_EMAIL" )
	grace_period 30s
	admin 127.0.0.1:2019
}

import /etc/caddy/sites/*.caddy
CADDYFILE
    else
        # Dev/VM: Caddy's internal CA (self-signed). No public DNS or email needed.
        # Trust it in the guest browser once with: sudo caddy trust
        echo "Configuring Caddy for dev TLS (internal self-signed CA)"
        tee /etc/caddy/Caddyfile >/dev/null <<'CADDYFILE'
{
	grace_period 30s
	admin 127.0.0.1:2019
}

import /etc/caddy/sites/*.caddy
CADDYFILE
    fi

    caddy validate --config /etc/caddy/Caddyfile
    systemctl enable caddy
    systemctl restart caddy

elif [[ "$WEBSERVER" == "nginx" ]]; then

    ## NGINX

    apt install -y nginx
    ufw app list
    ufw allow 'Nginx HTTP' && \
    ufw allow 'Nginx HTTPS'
    ufw app list
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=US/ST=LA/L=Mirage/O=Dis/CN=www.example.com" \
    -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

else
    echo "Unknown --webserver '$WEBSERVER' (expected: caddy | nginx)"
    exit 1
fi

## Postgresql

apt update
systemctl start postgresql.service

## Redis

apt install -y redis-server

## Node.js — via NodeSource (Ubuntu's apt Node is old); npm ships with it.

curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | bash -
apt install -y nodejs
node -v && npm -v

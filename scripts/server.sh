#!/bin/bash
echo "Running server set up"

## Reading arguments
PROD=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --prod)
            echo "Using production mode."
            PROD=1
            shift
            ;;
        --help)
            version="$2"
            shift 2
            ;;
        --verbose)
            verbose=true
            shift
            ;;
        --rebuild)
            rebuild=true
            shift
            ;;
        --dryrun)
            dryrun=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

printf "Argument prod is %s\n" "$PROD"

## Installing SSH
apt install openssh-server -y

## Creating workspace directory
echo "Creating /workspace"
mkdir /workspace
cd /workspace

chmod -R 777 ./

## Installing PHP

PHP_VER='8.4.7'
PHP_MAJOR="${PHP_VER:0:1}"
echo "Installing PHP $PHP_VER"
apt install -y pkg-config build-essential autoconf bison re2c \
                    libxml2-dev libsqlite3-dev zlib1g-dev libonig-dev
wget "https://github.com/php/php-src/archive/php-$PHP_VER.tar.gz"
tar --extract --gzip --file "php-$PHP_VER.tar.gz"
rm -f "php-$PHP_VER.tar.gz"
cd "php-src-php-$PHP_VER"
./buildconf --force
./configure --prefix="/usr/local/php${PHP_MAJOR}" \
--with-config-file-path="/etc/php${PHP_MAJOR}/cli" \
--with-config-file-scan-dir="/etc/php${PHP_MAJOR}/cli/conf.d/" \
--enable-zts --with-openssl --with-zlib --enable-bcmath --with-curl --enable-mbstring --with-pdo-mysql --with-pdo-pgsql --with-pgsql --enable-sockets --enable-soap
make -j4
make install

PHP_INSTALLED_VERSION=$(php -r "echo PHP_VERSION;")

if ["$PHP_INSTALLED_VERSION" != "$PHP_VER"]; then
    echo "PHP $PHP_VER installation failed."
    exit 1;
fi

if ["$PROD" -eq 1]; then
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

apt-get install -y libcurl4-openssl-dev libc-ares-dev postgresql postgresql-contrib libpq-dev
wget https://github.com/swoole/swoole-src/archive/refs/tags/v6.0.2.tar.gz
tar --extract --gzip --file v6.0.2.tar.gz
rm -f v6.0.2.tar.gz
cd swoole-src-6.0.2
phpize && \
./configure \
--enable-openssl --enable-swoole-curl --enable-cares --enable-swoole-pgsql --enable-swoole-thread
make
make install

echo 'extension=swoole.so' | tee -a /usr/local/lib/php.ini

## NGINX

apt install -y nginx
ufw app list
ufw allow 'Nginx HTTP' && \
ufw allow 'Nginx HTTPS'
ufw app list
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -subj "/C=US/ST=LA/L=Mirage/O=Dis/CN=www.example.com" \
-keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt

## Postgresql

apt update
apt install -y postgresql postgresql-contrib libpq-dev
systemctl start postgresql.service

## Redis

apt install -y redis-server

## Node js

apt update
apt install -y nodejs npm

#!/bin/bash
echo "Running server set up"

## Reading arguments
PROD = false
while getopts ":prod:help:" opt; do
  case $opt in
    prod) PROD=true ;;
    help) echo "Help value: $OPTARG" ;;
    \?) echo "Invalid option: -$OPTARG" ;;
  esac
done

printf "Argument prod is %s\n" "$PROD"
exit 1

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
./buildconf
./configure --prefix="/usr/local/php${PHP_MAJOR}" \
--with-config-file-path="/etc/php${PHP_MAJOR}/cli" \
--with-config-file-scan-dir="/etc/php${PHP_MAJOR}/cli/conf.d/" \
--enable-zts --with-openssl --with-zlib --enable-bcmath --with-curl --enable-mbstring --with-pdo-mysql --with-pdo-pgsql --with-pgsql --enable-sockets --enable-soap
make -j4
make install

if [PROD]; then
    cp ./php.ini-production /usr/local/lib/php.ini
else
    cp ./php.ini-development /usr/local/lib/php.ini
fi

apt install -y composer php-pear
pecl install inotify
printf "\n" | pecl install redis
echo 'extension=inotify.so' | tee -a /usr/local/lib/php.ini
echo 'extension=redis.so' | tee -a /usr/local/lib/php.ini
php -v


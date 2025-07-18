# Install PHP

[Go Back](./../README.md)

Login into Ubuntu

```bash
sudo apt install -y pkg-config build-essential autoconf bison re2c \
                    libxml2-dev libsqlite3-dev zlib1g-dev libonig-dev
wget https://github.com/php/php-src/archive/php-8.4.7.tar.gz
tar --extract --gzip --file php-8.4.7.tar.gz
rm -f php-8.4.7.tar.gz
cd php-src-php-8.4.7
./buildconf
./configure --prefix=/usr/local/php8 \
--with-config-file-path=/etc/php8/cli \
--with-config-file-scan-dir=/etc/php8/cli/conf.d/ \
--enable-zts --with-openssl --with-zlib --enable-bcmath --with-curl --enable-mbstring --with-pdo-mysql --with-pdo-pgsql --with-pgsql --enable-sockets --enable-soap
make -j4
```

If no errors

```bash
sudo make install

## Create php.ini file
# Production:
sudo cp ./php.ini-production /usr/local/lib/php.ini
# Development:
sudo cp ./php.ini-development /usr/local/lib/php.ini

## Need more flags?
./configure --help
```

Ctrl + Shift + L (vscode) to search for "--with-([^= [])*" with regex

## Components

```bash
sudo apt install -y composer
sudo apt-get install -y php-pear
sudo pecl install inotify
printf "\n" | sudo pecl install redis
echo 'extension=inotify.so' | sudo tee -a /usr/local/lib/php.ini
echo 'extension=redis.so' | sudo tee -a /usr/local/lib/php.ini
```

## Test

```bash
php -v
php -i
php --ini
pmp -m
```

[Go Back](./../README.md)
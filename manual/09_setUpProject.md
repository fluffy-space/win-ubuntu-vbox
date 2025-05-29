# Set up Project 

[Go Back](./../README.md)

```bash
mkdir paws-space && \
cd paws-space && \
mkdir files && \
mkdir vault && \
cd vault && \
echo '{}' | tee values.local.json && \
cd .. && \
git clone https://github.com/fluffy-space/paws-demo.git && \
cd paws-demo && \
composer install && \
cd viewi-app/js/ && npm install && \
cd ../..
```

## Create Database

```bash
sudo -u postgres createuser <username>
sudo -u postgres createdb <dbname>
sudo -u postgres psql -c "alter user <username> with encrypted password '<password>';"
sudo -u postgres psql -c "grant all privileges on database <dbname> to <username>;"
sudo -u postgres psql -c "\c <dbname>;" -c "CREATE EXTENSION citext;"
```

Example paws/paws/paws123:

```bash
sudo -u postgres createuser paws
sudo -u postgres createdb paws
sudo -u postgres psql -c "alter user paws with encrypted password 'paws123';"
sudo -u postgres psql -c "grant all privileges on database paws to paws;"
sudo -u postgres psql -c "\c paws;" -c "CREATE EXTENSION citext;"
```

Open VsCode

```bash
code .
```

[Go Back](./../README.md)
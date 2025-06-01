# Set up Project

[Go Back](./../README.md)

```bash
mkdir paws-space && \
cd paws-space && \
mkdir files && \
mkdir vault && \
cd vault && \
echo '{
    "ADMINS_ARRAY": [
        {
            "Email": "yourmail@example.com",
            "FirstName": "First",
            "LastName": "Last",
            "Password": "local123"
        }
    ],
    "HASH_SALT": "<random_hash>",
    "PG_PORT": 5432,
    "PG_DB": "<dbname>",
    "PG_USER": "<username>",
    "PG_PASSWORD": "<password>"
}' | tee values.local.json && \
cd .. && \
git clone https://github.com/fluffy-space/paws-demo.git && \
cd paws-demo && \
composer install && \
cd viewi-app/js/ && npm install && \
cd ../..
```

Example:

```bash
mkdir paws-space && \
cd paws-space && \
mkdir files && \
mkdir vault && \
cd vault && \
echo '{
    "ADMINS_ARRAY": [
        {
            "Email": "pawshub@paws.com",
            "FirstName": "Fluffy",
            "LastName": "Paws",
            "Password": "local123"
        }
    ],
    "HASH_SALT": "456gfdr53$#%$hfUgfhjjdUUUs111",
    "PG_PORT": 5432,
    "PG_DB": "paws",
    "PG_USER": "paws",
    "PG_PASSWORD": "paws123"
}' | tee values.local.json && \
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
sudo -u postgres psql -c "ALTER DATABASE <dbname> OWNER TO <username>;"
sudo -u postgres psql -c "\c <dbname>;" -c "CREATE EXTENSION citext;"
```

Example paws/paws/paws123:

```bash
sudo -u postgres createuser paws
sudo -u postgres createdb paws
sudo -u postgres psql -c "alter user paws with encrypted password 'paws123';"
sudo -u postgres psql -c "grant all privileges on database paws to paws;"
sudo -u postgres psql -c "ALTER DATABASE paws OWNER TO paws;"
sudo -u postgres psql -c "\c paws;" -c "CREATE EXTENSION citext;"
```

Open VsCode

```bash
code .
```

[Go Back](./../README.md)

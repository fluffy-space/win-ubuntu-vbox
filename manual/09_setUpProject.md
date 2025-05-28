# Set up Project 

[Go Back](./../README.md)


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
code .

[Go Back](./../README.md)
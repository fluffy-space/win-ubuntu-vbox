# Install NGINX

[Go Back](./../README.md)

```bash
sudo apt install -y nginx
sudo ufw app list
sudo ufw allow 'Nginx HTTP' && \
sudo ufw allow 'Nginx HTTPS'
sudo ufw app list
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
systemctl status nginx
```

[Go Back](./../README.md)
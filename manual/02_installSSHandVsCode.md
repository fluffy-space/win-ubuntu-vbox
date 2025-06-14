# Install SSH

[Go Back](./../README.md)

Configure port forwarding for SSH on VM
3022 to 22

Login into Ubuntu

sudo apt install openssh-server

Now you can login with SSH terminal

ssh -p 3022 admin@127.0.0.1

And run machine as headless

"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm {Name} --type headless

"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" startvm UP84S6 --type headless

Open VsCode and set up new SSH remote environment with string "ssh -p 3022 admin@127.0.0.1"

That should generate the config

  Host 127.0.0.1
    HostName 127.0.0.1
    Port 3022

Wait for VsCode server installation, open home directory.

# Using without password

## Identity key

On Host machine, generate file key

ssh-keygen -R 127.0.0.1

Using VsCode, copy/create files on Ubuntu at .ssh location

copy pub key to authorized_keys 

Change VsCode config to use your identity file

  Host 127.0.0.1
    HostName 127.0.0.1
    Port 3022
    IdentityFile ~/.ssh/id_ed25519

## Restore ownership

SSH logs:

sudo cat /var/log/auth.log

sudo chown -R admin:admin /home/admin

chmod go-w /home/admin

chmod 700 /home/admin/.ssh

chmod 600 /home/admin/.ssh/authorized_keys

[Go Back](./../README.md)
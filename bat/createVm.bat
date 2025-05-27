"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" createvm --name Ubu24 --basefolder "C:\VMs\Ubu24" --register
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" modifyvm Ubu24 --memory 4096 --vram 16 --cpus 4
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" createhd --filename "C:\VMs\Ubu24\Ubu24.vdi" --size 25000
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storagectl Ubu24 --name "SATA" --controller SATA --portcount 2
"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" storageattach Ubu24 --storagectl "IDE Controller" --disk "C:\VMs\Ubu24\Ubu24.vdi" --type HDD
pause
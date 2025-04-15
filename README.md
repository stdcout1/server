# NixOS Server
## How to deploy
run 
```
nixos-anywhere --flake .#generic-nixos-facter --gen
erate-hardware-config nixos-facter facter.json root@<ip> -i /path/to/ssh/key
```
then deploy using deploy-rs
```
deploy .#server
```

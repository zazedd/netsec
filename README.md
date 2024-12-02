# FutureTech
Network Systems Administration practical work, developed with Nix Flakes for total reproducibility.

## Running
```sh
nix run .#run
```

## Requirements
- [x] The company wants three web pages:
  - [x] Administration page: **admin.futuretech.pt** - Only accessed on the Internal network.
  - [x] Internal communication page: **gestao.futuretech.pt** - Only accessed on the internal network.
  - [x] Page for clients: **clientes.futuretech.pt** - Only accessed on the external network.
- [x] The company wants an email service and wants to use an email client, such as Thunderbird.
- [x] WiFi and Networks:
  - [x] Open workspace with capacity for up to 40 employees
  - [x] Two meeting rooms with a dedicated network, with a capacity for 10 employees.
- [x] Backup and log management:
  - [x] Backups should be carried out every day and always store only the last week.
  - [x] Only logs from the last week should be stored.

## Testing the DHCP

```bash
[guest@guest:~]$ sudo nmap --script broadcast-dhcp-discover
Starting Nmap 7.94 ( https://nmap.org ) at 2024-05-31 17:45 UTC
Pre-scan script results:
| broadcast-dhcp-discover:
|   Response 1 of 3:
|     Interface: eth0
|     IP Offered: 10.0.2.15
|     DHCP Message Type: DHCPOFFER
|     Server Identifier: 10.0.2.2
|     Subnet Mask: 255.255.255.0
|     Router: 10.0.2.2
|     Domain Name Server: 10.0.2.3
|     IP Address Lease Time: 1d00h00m00s
|   Response 2 of 3:
|     Interface: eth0
|     IP Offered: 10.0.1.2
|     DHCP Message Type: DHCPOFFER
|     Subnet Mask: 255.255.255.192
|     IP Address Lease Time: 1s
|     Server Identifier: 10.0.1.1
|   Response 3 of 3:
|     Interface: eth0
|     IP Offered: 10.0.3.2
|     DHCP Message Type: DHCPOFFER
|     Subnet Mask: 255.255.255.192
|     IP Address Lease Time: 1s
|_    Server Identifier: 10.0.3.1
WARNING: No targets were specified, so 0 hosts scanned.
Nmap done: 0 IP addresses (0 hosts up) scanned in 10.19 seconds
```

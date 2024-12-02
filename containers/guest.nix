# Tests DHCP server
{ pkgs, ... }:
{
  containers.guest = {
    autoStart = false;
    privateNetwork = true;
    hostBridge = "br0"; # Specify the bridge name
    # localAddress = "10.0.2.5/26";
    ephemeral = true; # stateless
    config = {
      services.getty.autologinUser = "guest";
      users.users."guest" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        password = "123";
      };

      security.sudo.wheelNeedsPassword = false;

      environment.systemPackages = with pkgs; [
        nmap
      ];

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ 67 ];
          allowedUDPPorts = [ 67 ];
        };

        dhcpcd = {
          enable = true;
          extraConfig = ''
            interface eth0
            static ip_address=10.0.1.5/26
            static routers=10.0.1.1
            static domain_name_servers=10.0.0.2
          '';
        };

        interfaces."eth0".useDHCP = pkgs.lib.mkForce true;

        defaultGateway = "10.0.1.1";
        useHostResolvConf = pkgs.lib.mkForce false;
        extraHosts = ''
          10.0.1.2 netsec.org
          10.0.1.2 admin.netsec.org
          10.0.1.2 gestao.netsec.org
          10.0.1.2 clientes.netsec.org
        '';
      };

      system.stateVersion = "24.05";
    };
  };
}

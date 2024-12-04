{ pkgs, inputs,  ... }:
{
  containers.attacker = {
    autoStart = false;
    privateNetwork = true;
    hostBridge = "br0"; # Specify the bridge name
    localAddress = "10.0.0.100/24";
    ephemeral = true; # stateless
    bindMounts = {
      # monta o /etc/resolv.conf do host, para partilhar os nameservers
      "/etc/resolv.conf" = {
        hostPath = "/etc/resolv.conf";
        isReadOnly = true;
      };
    };
    config = {

      imports = [ inputs.home-manager.nixosModules.home-manager ];

      services.getty.autologinUser = "hackerman";
      users.users."hackerman" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        password = "123";
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users."hackerman" = {
          home.stateVersion = "24.05";
          home.file = pkgs.lib.mkMerge [
            {
              "/home/hackerman/preload.rc".source = ../configs/preload.rc;
            }
            {
              "/home/hackerman/ransom.sh".source = ../ransoms/ransom.sh;
            }
            {
              "/home/hackerman/pk.pem".source = ../ransoms/pk.pem;
            }
            {
              "/home/hackerman/sk.pem".source = ../ransoms/sk.pem;
            }
          ];
        };
      };

      security.sudo.wheelNeedsPassword = false;

      environment.systemPackages = with pkgs; [
        dig
        metasploit
        samba
        smbclient-ng
        nmap
      ];

      networking = {
        firewall = {
          enable = false;
          allowedTCPPorts = [ 67 ];
          allowedUDPPorts = [ 67 ];
        };

        interfaces."eth0".useDHCP = pkgs.lib.mkForce true;

        useHostResolvConf = pkgs.lib.mkForce false;
      };

      system.stateVersion = "24.05";
    };
  };
}

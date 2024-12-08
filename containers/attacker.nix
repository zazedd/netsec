{ pkgs, inputs,  ... }:
let
  pythonPackages = pkgs.python3Packages;
  ippserver =
    let
      pname = "ippserver";
      version = "0.2";
    in
    pythonPackages.buildPythonPackage {
      inherit pname version;
      src = pkgs.fetchPypi {
        inherit pname version;
        sha256 = "sha256-hs3B0JRWx8OvT44Jv65MpG52MAV26y6+zow9hDaCt0U=";
      };
      doCheck = false;
    };
in
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
              "/home/hackerman/bash/ransom.sh".source = ../ransoms/bash/ransom.sh;
            }
            {
              "/home/hackerman/bash/pk.pem".source = ../ransoms/bash/pk.pem;
            }
            {
              "/home/hackerman/bash/sk.pem".source = ../ransoms/sk.pem;
            }
            {
              "/home/hackerman/python/decrypt.py".source = ../ransoms/python/decrypt.py;
            }
            {
              "/home/hackerman/python/ransomware.py".source = ../ransoms/python/ransomware.py;
            }
            {
              "/home/hackerman/python/secretKey.key".source = ../ransoms/python/secretKey.key;
            }
            }
              "/home/hackerman/lilu.o".source = ../ransoms/lilu.o;
            }
          ];
        };
      };

      security.sudo.wheelNeedsPassword = false;

      environment.systemPackages = with pkgs; [
        (python3.withPackages (ps: [ ippserver ]))

        dig
        metasploit
        samba
        smbclient-ng
        nmap
        rclone
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

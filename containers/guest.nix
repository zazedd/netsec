{ pkgs, inputs, oldcups,  ... }:
let 
  pdf = pkgs.fetchurl {
    url = "https://pdfobject.com/pdf/sample.pdf";
    hash = "sha256-Ip3vuwzubwJnOlzeKQ0Gc+daDcMc7EOYnIqypOyn4bs=";
  };
in
{
  containers.guest = {
    autoStart = false;
    privateNetwork = true;
    hostBridge = "br0"; # Specify the bridge name
    localAddress = "10.0.0.101/24";
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

      services.printing = {
        enable = true;
        package = oldcups.cups;
        startWhenNeeded = false;
        browsedConf = ''
          BrowseLocalProtocols DNSSD
          BrowseRemoteProtocols DNSSD
        '';
        allowFrom = [ "all" ];
        cups-pdf.enable = true;
        browsed.enable = true;
      };

      services.avahi = {
        enable = true;
        package = oldcups.avahi;
        nssmdns4 = true;
        openFirewall = true;
        publish = {
          enable = true;
          userServices = true;
        };
      };

      services.getty.autologinUser = "normalguy";
      users.users."normalguy" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        password = "123";
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users."normalguy" = {
          home.stateVersion = "24.05";
          home.file = pkgs.lib.mkMerge [
            {
              "/home/normalguy/important_file" = {
                text = "very important thing yes";
              };
            }
            {
              "/home/normalguy/cryptocurrency/bitcoinwallet" = {
                text = "bitcoin address";
              };
            }

            {
              "/home/normalguy/example.pdf" = {
                source = pdf;
              };
            }
          ];
        };
      };

      security.sudo.wheelNeedsPassword = false;

      environment.systemPackages = with pkgs; [
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

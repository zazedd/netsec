# DHCP server 
{ pkgs, ... }:
{
  containers.dhcp = {
    autoStart = false;
    ephemeral = true;
    privateNetwork = true;
    hostBridge = "br0"; # Specify the bridge name
    localAddress = "10.0.0.7/24";
    bindMounts = {
      # monta o /etc/resolv.conf do host, para partilhar os nameservers
      "/etc/resolv.conf" = {
        hostPath = "/etc/resolv.conf";
        isReadOnly = true;
      };
    };
    extraVeths = {
      "eth1" = {
        localAddress = "10.0.1.1/26";
        hostBridge = "br0";
      };
      "eth2" = {
        localAddress = "10.0.2.1/24";
        hostBridge = "br0";
      };
      "eth3" = {
        localAddress = "10.0.3.1/28";
        hostBridge = "br0";
      };
    };
    config = {
      services.getty.autologinUser = "root";

      services.nginx = {
        enable = true;
        recommendedTlsSettings = true;
        recommendedProxySettings = true;

        virtualHosts."clientes.netsec.org" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "https://clientes.netsec.org";
        };

        virtualHosts."admin.netsec.org" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "https://admin.netsec.org";
        };

        virtualHosts."gestao.netsec.org" = {
          enableACME = true;
          forceSSL = true;
          locations."/".proxyPass = "https://gestao.netsec.org";
        };
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "foo@bar.com";
      };

      services.kea = {
        dhcp4 = {
          enable = true;
          settings = {
            loggers = [
              {
                name = "kea-dhcp4";
                severity = "INFO";
                output_options = [
                  {
                    output = "syslog:local7";
                  }
                ];
              }
              {
                name = "kea-dhcp4.leases";
                severity = "INFO";
                output_options = [
                  {
                    output = "syslog:local7";
                  }
                ];
              }
              {
                name = "kea-dhcp4.dhcpsrv";
                severity = "INFO";
                output_options = [
                  {
                    output = "syslog:local7";
                  }
                ];
              }
            ];
            interfaces-config = {
              interfaces = [
                "eth1"
                "eth2"
                "eth3"
              ];
            };
            lease-database = {
              name = "/var/lib/kea/dhcp4.leases";
              persist = true;
              type = "memfile";
            };
            rebind-timer = 1;
            renew-timer = 1;
            subnet4 = [
              {
                id = 1;
                pools = [
                  {
                    pool = "10.0.1.2 - 10.0.1.42";
                  }
                ];
                subnet = "10.0.1.0/26";
              }
              {
                id = 2;
                pools = [
                  {
                    pool = "10.0.2.2 - 10.0.2.12";
                  }
                ];
                subnet = "10.0.2.0/26";
              }
              {
                id = 3;
                pools = [
                  {
                    pool = "10.0.3.2 - 10.0.3.12";
                  }
                ];
                subnet = "10.0.3.0/26";
              }
            ];
            valid-lifetime = 1;
          };
        };
      };

      services.rsyslogd = {
        enable = true;
        extraConfig = ''
          *.* /var/log/all.log
          *.* @@10.0.0.4:514
        '';
      };

      services.logrotate = {
        enable = true;

        settings."/var/log/all.log" = {
          compress = true;
          postrotate = ''
            find /var/log/*.log -mtime +7 -exec rm {} \;
          '';
          frequency = "hourly";
          rotate = 4;
        };
      };

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [
            67
            443
          ];
          allowedUDPPorts = [
            67
            443
          ];
        };

        interfaces."eth1".name = "eth1";
        interfaces."eth2".name = "eth2";
        interfaces."eth3".name = "eth3";

        useHostResolvConf = pkgs.lib.mkForce false;
      };

      system.stateVersion = "24.05";
    };
  };
}

{
  pkgs,
  options,
  config,
  inputs,
  oldpkgs,
  ...
}:
let
  simple_page = str: ''
    <html lang="en">
    <body>
        <h1>${str}</h1>
    </body>
    </html>
  '';
in
{
  containers.websites = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostBridge = "br0"; # Specify the bridge name
    localAddress = "10.0.0.3/24";
    config = {

      imports = [ inputs.home-manager.nixosModules.home-manager ];

      services.getty.autologinUser = "root";
      users.users."samba_user" = {
        isNormalUser = true;
        hashedPassword = "";
      };

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        users."samba_user" = {
          home.stateVersion = "24.05";
          home.file = pkgs.lib.mkMerge [
            {
              "/home/samba_user/important_file" = {
                text = "very important thing yes";
              };
            }
            {
              "/home/samba_user/stuff/bitcoinwallet" = {
                text = "bitcoin address";
              };
            }
          ];
        };
        users."root" = {
          home.stateVersion = "24.05";
          home.file = pkgs.lib.mkMerge [
            {
              "/home/root/.ssh/id_ed25519" = {
                source = ../configs/id_ed25519;
              };
            }
          ];
        };
      };

      systemd.services."enable-promiscuous-mode" = {
        description = "Promiscuous mode on eth0";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          ExecStart = "ip link set eth0 promisc on";
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      environment.systemPackages = with pkgs; [
        (python3.withPackages (ps: [ ps.cryptography ]))
        openssl
        snort
        vim
      ];

      security.sudo.wheelNeedsPassword = false;
      users.users.root.hashedPassword = "";

      services.borgbackup = {
        jobs."websites" = {
          paths = "/etc/www";
          compression = "none";
          environment = {
            BORG_RSH = "ssh -i /root/.ssh/id_ed25519";
          };
          encryption = {
            mode = "none";
          };
          repo = "borg@10.0.0.6:/var/bak/websites";
          startAt = "daily";
        };
      };

      services.samba = {
        enable = true;
        package = oldpkgs.samba; # version 4.5.8, exploitable through CVE-2017-7494
        openFirewall = true;
        settings = {
          public = {
            comment = "Public samba share.";
            browseable = "yes";
            security = "user";
            writeable = "yes";
            path = "/tmp/samba";
            public = "yes";
            "guest ok" = "yes";
            "create mask" = "0777";
            "directory mask" = "0777";
            # this setting disables the exploit!
            # "nt pipe support" = "no";
          };
        };
      };

      # email server
      services.maddy = {
        enable = true;
        primaryDomain = "netsec.org";
        openFirewall = true;
        tls = {
          loader = "file";
          certificates = [
            {
              keyPath = "/var/lib/acme/mx1.netsec.org/key.pem";
              certPath = "/var/lib/acme/mx1.netsec.org/cert.pem";
            }
          ];
        };

        # Enable TLS listeners. Configuring this via the module is not yet
        # implemented, see https://github.com/NixOS/nixpkgs/pull/153372
        config =
          builtins.replaceStrings
            [
              "imap tcp://0.0.0.0:143"
              "submission tcp://0.0.0.0:587"
            ]
            [
              "imap tls://0.0.0.0:993 tcp://0.0.0.0:143"
              "submission tls://0.0.0.0:465 tcp://0.0.0.0:587"
            ]
            (options.services.maddy.config.default + "\n" + "log syslog");
        ensureAccounts = [
          "user1@netsec.org"
          "user2@netsec.org"
          "postmaster@netsec.org"
        ];
        ensureCredentials = {
          # This will make passwords world-readable in the Nix store
          "user1@netsec.org".passwordFile = "${pkgs.writeText "postmaster" "test"}";
          "user2@netsec.org".passwordFile = "${pkgs.writeText "postmaster" "test"}";
          "postmaster@netsec.org".passwordFile = "${pkgs.writeText "postmaster" "test"}";
        };
      };

      environment.etc = {
        "/www/admin/index.html" = {
          enable = true;
          text = simple_page "Admin";
        };

        "/www/gestao/index.html" = {
          enable = true;
          text = simple_page "Gestão";
        };

        "/www/clientes/index.html" = {
          enable = true;
          text = simple_page "Clientes";
        };

        # "/snort/snort.conf" = {
        #   enable = true;
        #   source = ../configs/snort.conf;
        # };
        #
        # "/snort/classification.config" = {
        #   enable = true;
        #   source = ../configs/classification.config;
        # };
        #
        # "/snort/reference.config" = {
        #   enable = true;
        #   source = ../configs/reference.config;
        # };
        #
        # "/snort/rules/CVE-2017-7494.rules" = {
        #   enable = true;
        #   source = ../configs/CVE-2017-7494.rules;
        # };
        #
        # "/snort/rules/nmap.rules" = {
        #   enable = true;
        #   source = ../configs/nmap.rules;
        # };
        #
        # "/snort/rules/meterpreter.rules" = {
        #   enable = true;
        #   source = ../configs/meterpreter.rules;
        # };
      };

      services.nginx = {
        enable = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;

        appendHttpConfig = ''
          error_log syslog:server=10.0.0.4:514,facility=local7,tag=nginx,severity=error;
          access_log syslog:server=10.0.0.4:514,facility=local7,tag=nginx,severity=info;
        '';

        virtualHosts."clientes.netsec.org" = {
          addSSL = true;
          enableACME = true;
          root = "/etc/www/clientes";
        };

        virtualHosts."admin.netsec.org" = {
          addSSL = true;
          enableACME = true;
          root = "/etc/www/admin";
        };

        virtualHosts."gestao.netsec.org" = {
          addSSL = true;
          enableACME = true;
          root = "/etc/www/gestao";
        };
      };

      security.acme = {
        acceptTerms = true;
        defaults.email = "foo@bar.com";
        certs = {
          "mx1.netsec.org" = {
            group = config.services.maddy.group;
            webroot = "/var/lib/acme/acme-challenge/";
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
            24
            25
            53
            80
            443
          ];
          allowedUDPPorts = [
            24
            25
            53
            80
            443
          ];
        };

        interfaces.eth0.ipv4 = {
          routes = [
            {
              address = "82.103.20.0";
              prefixLength = 24;
              via = "10.0.0.5";
            }
          ];
        };

        defaultGateway = { 
          address = "10.0.0.5";
          interface = "eth0";
        };

        useHostResolvConf = pkgs.lib.mkForce false;
      };

      services.resolved.enable = true;

      system.stateVersion = "24.05";
    };
  };
}

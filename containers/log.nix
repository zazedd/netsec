# Logging server
{ pkgs, ... }:
{
  containers.log = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostBridge = "br0"; # Specify the bridge name
    localAddress = "10.0.0.4/24";
    bindMounts = {
      # monta o /etc/resolv.conf do host, para partilhar os nameservers
      "/etc/resolv.conf" = {
        hostPath = "/etc/resolv.conf";
        isReadOnly = true;
      };
    };
    config = {
      services.getty.autologinUser = "root";
      users.users."guest" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        password = "123";
      };

      security.sudo.wheelNeedsPassword = false;

      services.borgbackup = {
        jobs."log" = {
          paths = "/var/log";
          compression = "none";
          environment = {
            BORG_RSH = "ssh -i /root/.ssh/id_ed25519";
          };
          encryption = {
            mode = "none";
          };
          repo = "borg@10.0.0.6:/var/bak/log";
          startAt = "daily";
        };
      };

      services.logrotate = {
        enable = true;

        settings."multiple paths" = {
          compress = true;
          files = [
            "/var/log/websites/*"
            "/var/log/dhcp/*"
          ];

          postrotate = ''
            find /var/log/websites/*.log -mtime +7 -exec rm {} \;
            find /var/log/dhcp/*.log -mtime +7 -exec rm {} \;
          '';
          frequency = "hourly";
          rotate = 4;
        };
      };

      services.rsyslogd = {
        enable = true;
        extraConfig = ''
          # Provides TCP syslog reception
          module(load="imtcp")
          input(type="imtcp" port="514")

          # Provides UDP syslog reception
          module(load="imudp")
          input(type="imudp" port="514")

          template(name="RemoteLogs" type="string" string="/var/log/%HOSTNAME%/%PROGRAMNAME%.log")

          *.* ?RemoteLogs
        '';
      };

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ 514 ];
          allowedUDPPorts = [ 514 ];
        };

        useHostResolvConf = pkgs.lib.mkForce false;
      };

      system.stateVersion = "24.05";
    };
  };
}

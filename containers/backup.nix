{ pkgs, ... }:
{
  containers.backup = {
    autoStart = false;
    ephemeral = true;
    privateNetwork = true;
    hostBridge = "br0"; # Specify the bridge name
    localAddress = "10.0.0.6/24";
    bindMounts = {
      # monta o /etc/resolv.conf do host, para partilhar os nameservers
      "/etc/resolv.conf" = {
        hostPath = "/etc/resolv.conf";
        isReadOnly = true;
      };
    };
    config = {
      services.getty.autologinUser = "root";

      services.sshd = {
        enable = true;
      };

      services.openssh = {
        enable = true;
      };

      environment.etc = {
        "prune.sh" = {
          enable = true;
          text = ''
            borg prune -v --list /var/bak/websites --keep-within=7d
            borg prune -v --list /var/bak/log --keep-within=7d
          '';
        };
      };

      services.cron = {
        enable = true;
        # Run the prune script everyday at 2 AM
        systemCronJobs = [
          "0 2 * * * /etc/prune.sh"
        ];
      };

      services.borgbackup = {
        repos.bak = {
          path = "/var/bak/";
          allowSubRepos = true;
          # You need to generate a key-pair on the 
          # container and put its public key here
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO0Reqd2yr2gEOYmhS+IVUkKEVY2cMngGUwYgXBbjuQv root@websites"
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDC7roETuDWbxPKEF5rWQAhPjL9Lqu9caqbjUsoXYzvt root@log"
          ];
        };
      };

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ 22 ];
          allowedUDPPorts = [ 22 ];
        };

        useHostResolvConf = pkgs.lib.mkForce false;
      };

      system.stateVersion = "24.05";
    };
  };
}

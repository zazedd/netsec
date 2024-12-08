{ pkgs, ... }:
{
  containers.backup = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostBridge = "br0"; # Specify the bridge name
    localAddress = "10.0.0.5/24";
    bindMounts = {
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
        systemCronJobs = [
          "0 2 * * * /etc/prune.sh"
        ];
      };

      services.borgbackup = {
        repos.bak = {
          path = "/var/bak/";
          allowSubRepos = true;
          authorizedKeys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDihLWKMmQ+BSOBCMbBOJX6Zm/tBM00I7F4aL3W2POuM test@test.test"
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

{ pkgs, home-manager, ... }: 
{
  services.getty.autologinUser = "guest";
  users.users."guest" = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    password = "123";
  };

  security.sudo.wheelNeedsPassword = false;

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  environment.systemPackages = with pkgs; [
    xterm

    tmux
    dig
    vim
    inetutils
    openssl
    gsasl
    gnutls
  ];

  boot.kernel.sysctl."max_user_instances" = 8192;

  # Network configuration.
  networking = {
    # allow containers to use external network
    # nat.enable = true;
    # nat.internalInterfaces = ["ve-+"];
    # nat.externalInterface = "eth0";

    bridges.br0.interfaces = [ "eth0" ];

    useDHCP = false;
    interfaces."br0".useDHCP = false;

    interfaces."br0".ipv4 = {
      addresses = [
        {
          address = "10.0.0.1";
          prefixLength = 24;
        }
      ];
    };

    defaultGateway = "10.0.0.1";
    nameservers = [ "10.0.0.2" ];
    extraHosts = "";
  };

  system.stateVersion = "24.05";
}

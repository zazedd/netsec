{ pkgs, home-manager, options, lib, ... }: 
{
  services.getty.autologinUser = "vm";
  users.users."vm" = {
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
    snort
    tcpdump
  ];

  boot.kernel.sysctl."max_user_instances" = 8192;

  environment.etc = {
    "/snort/snort.conf" = {
      enable = true;
      source = ../configs/snort.conf;
    };

    "/snort/classification.config" = {
      enable = true;
      source = ../configs/classification.config;
    };

    "/snort/reference.config" = {
      enable = true;
      source = ../configs/reference.config;
    };

    "/snort/rules/CVE-2017-7494.rules" = {
      enable = true;
      source = ../configs/CVE-2017-7494.rules;
    };

    "/snort/rules/nmap.rules" = {
      enable = true;
      source = ../configs/nmap.rules;
    };

    "/snort/rules/meterpreter.rules" = {
      enable = true;
      source = ../configs/meterpreter.rules;
    };
  };

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

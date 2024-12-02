({ pkgs, home-manager, ... }: {
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
  
  # services.xserver.enable = true;
  # services.xserver.windowManager.dwm.enable = true;
  #
  # services.xserver.libinput.enable = true;
  # services.xserver.libinput.mouse.accelProfile = "adaptive";
  # services.xserver.libinput.mouse.accelSpeed = "-0.5";
  # services.xserver.libinput.mouse.scrollMethod = "twofinger";
  #
  # services.xserver.libinput.touchpad = {
  #   accelProfile = "adaptive";
  #   accelSpeed = "-0.5";
  #   scrollMethod = "twofinger";
  #   tapping = true;
  # };

  environment.systemPackages = with pkgs; [
    dig
    vim
    inetutils
    openssl
    gsasl
    gnutls
    # thunderbird
    # dmenu
  ];

  boot.kernel.sysctl."max_user_instances" = 8192;

  # systemd.network.enable = true;
  # systemd.network.networks."10-br0"= {
  #   enable = true;
    # name = "br0";
    # DHCP = "no";
  # };

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
          address = "10.0.0.0";
          prefixLength = 24;
        }
        {
          address = "10.0.1.0";
          prefixLength = 24;
        }
        {
          address = "10.0.2.0";
          prefixLength = 24;
        }
        {
          address = "10.0.3.0";
          prefixLength = 24;
        }
        {
          address = "82.103.20.1";
          prefixLength = 24;
        }
      ];
      routes = [
        {
          address = "82.103.20.0";
          prefixLength = 24;
          via = "10.0.0.1";
        }
        {
          address = "10.0.0.0";
          prefixLength = 24;
          via = "82.103.20.2";
        }
        {
          address = "10.0.0.0";
          prefixLength = 24;
          via = "10.0.1.0";
        }
        {
          address = "10.0.0.0";
          prefixLength = 24;
          via = "10.0.2.0";
        }
        {
          address = "10.0.0.0";
          prefixLength = 24;
          via = "10.0.3.0";
        }
        {
          address = "10.0.1.0";
          prefixLength = 24;
          via = "10.0.0.0";
        }
        {
          address = "10.0.2.0";
          prefixLength = 24;
          via = "10.0.0.0";
        }
        {
          address = "10.0.3.0";
          prefixLength = 24;
          via = "10.0.0.0";
        }
      ];
    };

    defaultGateway = "10.0.0.1";
    nameservers = [ "10.0.0.2" ];
    extraHosts = "";
  };

  system.stateVersion = "24.05";
})

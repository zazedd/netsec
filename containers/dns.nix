# DNS for the whole network
{ pkgs, ... }:
{
  containers.dns = {
    autoStart = true;
    ephemeral = true;
    privateNetwork = true;
    hostBridge = "br0"; # Specify the bridge name
    localAddress = "10.0.0.2/24";
    config = {
      users.users."guest" = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        password = "123";
      };

      services.getty.autologinUser = "guest";

      security.sudo.wheelNeedsPassword = false;
      security.acme.acceptTerms = true;
      security.acme.defaults.email = "security@example.com";

      # dns server
      services.nsd = {
        enable = true;

        rootServer = true;
        interfaces = pkgs.lib.mkForce [ ];

        keys."tsig.netsec.org." = {
          algorithm = "hmac-sha256";
          keyFile = pkgs.writeTextFile {
            name = "tsig.netsec.org.";
            text = "aR3FJA92+bxRSyosadsJ8Aeeav5TngQW/H/EF9veXbc=";
          };
        };

        zones."netsec.org.".data =
          let
            # Careful: this needs to be changed according to what your maddy generated.
            # The key is in the /var/lib/maddy/dkim_keys directory
            domainkey = ''
              v=DKIM1; k=rsa; p=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA964bgacUNFtEpFGnwMsf4b//+4Td4IFYorvBdNc/s6MYYRQNYgKyLMxARZWrePH3IeHQQ9VNFlmtWWEV5OoKwtDQdQYRUa2NsLSeJeTZ9N/uWQTUUGeeerTydbuxFfcSf4yfvwoh7sVjs9FiLRX6ua5WhK/22z3yP1yq57Xw6I7713c7UBs2VizNbT4ceNDB2W0+oPKsUuqA6vEa/6p3ooO5UB4TFUctHoxZH3dpy34QvHF2ddMWXfxnc5oRvqUXmmUpLWtobtWUBE4mvX/8zbaeCcTbAFnFsDfAc+RG9jSWb8IDbwjxklDkC4Qbn5tUd0Jp4XA5sVkWwVkPG+4bQwIDAQAB
            '';
            segments = ((pkgs.lib.stringLength domainkey) / 255);
            domainkeySplitted = map (x: pkgs.lib.substring (x * 255) 255 domainkey) (pkgs.lib.range 0 segments);
          in
          ''
            @ SOA ns.netsec.org. noc.netsec.org. 666 7200 3600 1209600 3600
            @ NS ns.netsec.org.
            @ MX 10 mx1
            ns                            A        10.0.0.3 
            netsec.org.          IN    A        10.0.0.3
            samba.netsec.org.    IN    CNAME    netsec.org.
            admin.netsec.org.    IN    CNAME    netsec.org.
            gestao.netsec.org.   IN    CNAME    netsec.org.
            clientes.netsec.org. IN    CNAME    netsec.org.

            mx1                           A        10.0.0.3
            @                             TXT      "v=spf1 mx ~all"
            mx1                           TXT      "v=spf1 mx ~all"
            _dmarc                        TXT      "v=DMARC1; p=quarantine; ruf=mailto:postmaster@netsec.org
            _mta-sts                      TXT      "v=STSv1; id=1"
            _smtp._tls                    TXT      "v=TLSRPTv1;rua=mailto:postmaster@netsec.org"
            default._domainkey            TXT      "${pkgs.lib.concatStringsSep "\" \"" domainkeySplitted}"
          '';

        # Reverse DNS lookup. important for email
        zones."0.0.10.in-addr.arpa.".data = ''
          @ SOA ns.netsec.org. noc.netsec.org. 666 7200 3600 1209600 3600
          @ NS ns.netsec.org.
          3.0.0.10.in-addr.arpa.  IN    PTR      mx1.netsec.org.
        '';

        zones."netsec.org.".provideXFR = [ "0.0.0.0 tsig.netsec.org." ];
      };

      networking = {
        firewall = {
          enable = true;
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ];
        };

        useHostResolvConf = pkgs.lib.mkForce false;
      };

      system.stateVersion = "24.05";
    };
  };
}

{ pkgs, ... }:
{
  programs.bash.enable = true;

  home.stateVersion = "23.11";
  home.file = pkgs.lib.mkMerge [
    {
      "/home/guest/.config/neomutt/neomuttrc" = {
        text = builtins.readFile ../configs/neomutt;
      };
    }
    {
      "/home/guest/setup.sh" = {
        text = builtins.readFile ../configs/setup;
      };
    }
  ];

  programs.neomutt = {
    enable = true;
  };
}
# extraGroups = [ "wheel" ];

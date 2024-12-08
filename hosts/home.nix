{ pkgs, ... }:
{
  programs.bash.enable = true;

  home.stateVersion = "24.05";
  home.file = pkgs.lib.mkMerge [
    {
      "/home/vm/.config/neomutt/neomuttrc" = {
        text = builtins.readFile ../configs/neomutt;
      };
    }
    {
      "/home/vm/setup.sh" = {
        text = builtins.readFile ../configs/setup;
      };
    }
  ];

  programs.neomutt = {
    enable = true;
  };
}
# extraGroups = [ "wheel" ];

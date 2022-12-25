{
  config,
  pkgs,
  lib,
  ...
} @inputs:
with lib;
let
  xdg = config.home-manager.users.nixos.xdg;
in {


  home = {

    sessionVariables = {
      EDITOR = "${pkgs.emacs-nox}/bin/emacs";
    };

    packages = [
      pkgs.emacs-nox
      pkgs.zsh
    ];

  };

  xdg.enable = true;

  programs.home-manager = {
    enable = true;
  };

  programs.zsh = {

    enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
      theme = "robbyrussell";
    };

  };

}

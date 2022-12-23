{ config, pkgs, lib, ... }:
with lib;
let
  xdg = config.home-manager.users."${config.lima-vm.user.name}".xdg;
in
{
  imports = [
    ./session-variables.nix
  ];

  home-manager = pkgs.lib.setAttrByPath [ "users" config.lima-vm.user.name ] {
    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # Home Manager needs a bit of information about you and the
    # paths it should manage.
    home.username = mkForce config.lima-vm.user.name;
    home.homeDirectory = mkForce "/home/${config.lima-vm.user.name}";

    home.packages = with pkgs; [ ];

    fonts.fontconfig.enable = mkForce true;

    programs.dircolors.enable = true;
    programs.dircolors.enableZshIntegration = true;

    xdg.enable = true;

    # xdg.configFile."git/config".text = import ./dotfiles/git/config.nix { inherit config; inherit pkgs; };
    # xdg.configFile."git/gitmessage".text = import ./dotfiles/git/gitmessage.nix { inherit config; inherit pkgs; };
    # xdg.configFile."git/global_gitignore".text = import ./dotfiles/git/global_gitignore.nix { inherit config; inherit pkgs; };
    xdg.configFile."dircolors".source = ./dotfiles/dircolors;
    xdg.configFile."user-dirs.dirs".source = ./dotfiles/user-dirs.dirs;
    xdg.configFile."user-dirs.locale".source = ./dotfiles/user-dirs.locale;
    xdg.configFile."vifm/vifmrc".source = ./dotfiles/vifm/vifmrc;
    xdg.configFile."vifm/colors/base16.vifm".source = ./dotfiles/vifm/colors/base16.vifm;

    # Ensure nvim backup directory gets created
    # Workaround for E510: Can't make backup file (add ! to override)
    xdg.dataFile."nvim/backup/.keep".text = "";
    xdg.dataFile."nvim/templates/.keep".text = "";
    xdg.dataFile."shell.nix.tmpl" = {
      text = ''
        let
          unstable = import (fetchTarball https://github.com/nixos/nixpkgs/archive/nixos-unstable.tar.gz) { };
        in
        { nixpkgs ? import <nixpkgs> {} }:
        with nixpkgs; mkShell {
          buildInputs = [
          ];
        }
      '';
      target = "nvim/templates/shell.nix.tmpl";
    };

    # Allow unfree packages only on a user basis, not on a system-wide basis
    xdg.configFile."nixpkgs/config.nix".text = " { allowUnfree = true; } ";

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    home.stateVersion = "22.05";
  };
}

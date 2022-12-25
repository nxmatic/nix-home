{
  config,
  pkgs,
  lib,
  ...
} @inputs:
with lib;
let
  homeDirectory = config.home.homeDirectory;
in {

  home = {

    sessionVariables = {
      EDITOR = "${pkgs.emacs-nox}/bin/emacs";
    };

    packages = [
      pkgs.emacs-nox
      pkgs.zsh
    ];

    file."nixos-home-rc" = {
      source = ./rc.zsh;
      target = ".zshrc.d/nix-home.zsh";
    };

  };

  xdg = {
    enable = true;
  };

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

    initExtra = ''
    # load extends rc files
    for file in ~/.zshrc.d/*.zsh; do source ''${file}; done
    '';

  };

  systemd.user.services.nixos-home-rc = {

    Unit = {
      Description = "Setup nixos-home on host";
    };
    
    Install = {
      WantedBy = [ "default.target" ];
    };

    Service = {
      User = "nixos";
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart =  "${pkgs.zsh}/bin/zsh ${config.home.homeDirectory}/.zshrc.d/nixos-home.zsh";
    };
    
  };

}

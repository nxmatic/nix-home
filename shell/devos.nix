{
  pkgs,
  extraModulesPath,
  inputs,
  lib,
  ...
}: let
  inherit
    (pkgs)
    just
    agenix
    cachix
    editorconfig-checker
    mdbook
    nixUnstable
    treefmt
    nvfetcher-bin
    ;
in {
  _file = toString ./.;

  imports = ["${extraModulesPath}/git/hooks.nix"];
}

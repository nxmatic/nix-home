{
  self,
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) fileContents;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
}

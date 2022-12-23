{ lib, config, pkgs, ... }:
with lib;
let
  cfg = config.lima-vm;
in
{
  options.lima-vm = {
    cidata-mnt = mkOption {
      description = "cidata Mount path";
      type = types.str;
      default = "/mnt/lima-cidata";
    };
    user = {
      name = mkOption {
        description = "User login name";
        type = types.nullOr types.str;
        default = "nixos";
      };
      description = mkOption {
        description = "User description";
        type = types.nullOr types.str;
        default = "The main lima VM user";
      };
      password = mkOption {
        description = "User password";
        type = types.nullOr types.str;
        default = null;
      };
      publicKeys = mkOption {
        description = "User SSH public keys";
        type = types.listOf types.path;
        default = [ ];
      };
      fullName = mkOption {
        description = "User full name";
        type = types.nullOr types.str;
        default = null;
      };
      email = mkOption {
        description = "User email address";
        type = types.nullOr types.str;
        default = null;
      };
      gpgKeyId = mkOption {
        description = "GPG Key ID";
        type = types.nullOr types.str;
        default = null;
      };
    };
  };
}

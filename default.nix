let
  inherit (default.inputs.nixos) lib;

  default = (import ./lib/compat).defaultNix;

  systemOutputs = default.outputs;
in
  systemOutputs // {shell = import ./shell.nix;}

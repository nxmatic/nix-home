{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
  };
  outputs = { self, nixpkgs, ... }: {
    packages.x86_64-linux = {
      box = nixpkgs.legacyPackages.x86_64-linux.nixosGenerate {
        modules = [
          ./lima-box.nix
        ];
        format = "raw-efi";
      };
    };
  };
}

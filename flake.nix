{
  description = "A highly structured configuration database.";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    # Track channels with commits tested and built by hydra
    nixos.url = "github:nixos/nixpkgs/nixos-22.11";

    home.url = "github:nix-community/home-manager/release-22.05";
    home.inputs.nixpkgs.follows = "nixos";

    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs-darwin-stable";

    deploy.url = "github:serokell/deploy-rs";
    deploy.inputs.nixpkgs.follows = "nixos";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixos";

    nvfetcher.url = "github:berberman/nvfetcher";
    nvfetcher.inputs.nixpkgs.follows = "nixos";

    naersk.url = "github:nmattia/naersk";
    naersk.inputs.nixpkgs.follows = "nixos";

    nixos-hardware.url = "github:nixos/nixos-hardware";

    nixos-generators.url = "github:nix-community/nixos-generators/1.6.0";
    nixos-generators.inputs.nixpkgs.follows = "nixos";
  };

  outputs =
    { self
    , nixos
    , home
    , nixos-hardware
    , nur
    , agenix
    , nvfetcher
    , deploy
    , nixpkgs
    , ...
    } @ inputs:
    {
      inherit self inputs;

      channelsConfig = {allowUnfree = true;};

      channels = {
        nixos = {
          imports = [(import ./overlays)];
          overlays = [
            nur.overlay
            agenix.overlay
            nvfetcher.overlay
            ./pkgs/default.nix
          ];
        };
      };

      lib = import ./lib {lib = nixos.lib;};

      sharedOverlays = [
        (final: prev: {
          __dontExport = true;
          lib = prev.lib.extend (lfinal: lprev: {
            our = self.lib;
          });
        })

        nur.overlay
        agenix.overlay
        nvfetcher.overlay

        (import ./pkgs)
      ];

      nixos = {
        hostDefaults = {
          system = "x86_64-linux";
          channelName = "nixos";
          imports = [(import ./modules)];
          modules = [
            {lib.our = self.lib;}
            home.nixosModules.home-manager
            agenix.nixosModules.age
          ];
        };

        imports = [(import ./hosts/nixos)];

        hosts = {
          /*
          * set host-specific properties here
          */
          NixOS = {
          };
          LimaVM = {
          };
        };
        importables = rec {
          profiles =
            (import ./profiles) // {
              users = (import ./users);
            };
          suites = with profiles; rec {
            base = [ core.nixos users.nixos users.root ];
#           home = base ++ [ profiles.home ];
            lima = base ++ [ profiles.lima ];
          };
        };
      };

      darwin = {
        hostDefaults = {
          system = "x86_64-darwin";
          channelName = "nixpkgs-darwin-stable";
          imports = [(import ./modules)];
          modules = [
            {lib.our = self.lib;}
            home.darwinModules.home-manager
            agenix.nixosModules.age
          ];
        };

        imports = [(import ./hosts/darwin)];
        hosts = {
          /*
           * set host-specific properties here
           */
          Mac = {};
        };
        importables = rec {
          profiles =
            (import ./profiles)
            // {
              users = (import ./users);
            };
          suites = with profiles; rec {
            base = [core.darwin users.darwin];
          };
        };
      };

      home = {
        imports = [(import ./users/modules)];
        modules = [];
        importables = rec {
          profiles = (import ./users/profiles);
          suites = with profiles; rec {
            base = [direnv git];
          };
        };
        users = {
          # TODO: does this naming convention still make sense with darwin support?
          #
          # - it doesn't make sense to make a 'nixos' user available on
          #   darwin, and vice versa
          #
          # - the 'nixos' user might have special significance as the default
          #   user for fresh systems
          #
          # - perhaps a system-agnostic home-manager user is more appropriate?
          #   something like 'primaryuser'?
          #
          # all that said, these only exist within the `hmUsers` attrset, so
          # it could just be left to the developer to determine what's
          # appropriate. after all, configuring these hm users is one of the
          # first steps in customizing the template.
          root = { suites, ... } : { imports = suites.base ++ [ ./users/root/home.nix ]; };
          nixos = { suites, ... } : { imports = suites.base ++ [ ./users/nixos/home.nix ]; };
          darwin = { suites, ... } : { imports = suites.base; };
        }; # (import ./users/hm);
      };

      devshell = ./shell;

      # TODO: similar to the above note: does it make sense to make all of
      # these users available on all systems?
      homeConfigurations =
         (import ./homeConfigurations self.darwinConfigurations)
         (import ./homeConfigurations self.nixosConfigurations);

      deploy.nodes = (import ./deployNodes self.nixosConfigurations) {};
    };
}

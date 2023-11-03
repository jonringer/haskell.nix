{
  description = "Alternative Haskell Infrastructure for Nixpkgs";

  inputs = {
    nixpkgs.follows = "nixpkgs-unstable";
    nixpkgs-2003 = { url = "github:NixOS/nixpkgs/nixpkgs-20.03-darwin"; };
    nixpkgs-2105 = { url = "github:NixOS/nixpkgs/nixpkgs-21.05-darwin"; };
    nixpkgs-2111 = { url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin"; };
    nixpkgs-2205 = { url = "github:NixOS/nixpkgs/nixpkgs-22.05-darwin"; };
    nixpkgs-2211 = { url = "github:NixOS/nixpkgs/nixpkgs-22.11-darwin"; };
    nixpkgs-unstable = { url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };
    flake-compat = { url = "github:input-output-hk/flake-compat/hkm/gitlab-fix"; flake = false; };
    flake-utils = { url = "github:hamishmack/flake-utils/hkm/nested-hydraJobs"; };
    "hls-1.10" = { url = "github:haskell/haskell-language-server/1.10.0.0"; flake = false; };

    hackage = {
      url = "github:input-output-hk/hackage.nix";
      flake = false;
    };
    stackage = {
      url = "github:input-output-hk/stackage.nix";
      flake = false;
    };
    cabal-32 = {
      url = "github:haskell/cabal/3.2";
      flake = false;
    };
    cabal-34 = {
      url = "github:haskell/cabal/3.4";
      flake = false;
    };
    cabal-36 = {
      url = "github:haskell/cabal/3.6";
      flake = false;
    };
    "ghc-8.6.5-iohk" = {
      type = "github";
      owner = "input-output-hk";
      repo = "ghc";
      ref = "release/8.6.5-iohk";
      flake = false;
    };
    hpc-coveralls = {
      url = "github:sevanspowell/hpc-coveralls";
      flake = false;
    };
    old-ghc-nix = {
      url = "github:angerman/old-ghc-nix/master";
      flake = false;
    };
    HTTP = {
      url = "github:phadej/HTTP";
      flake = false;
    };
    iserv-proxy = {
      type = "git";
      url = "https://gitlab.haskell.org/hamishmack/iserv-proxy.git";
      ref = "hkm/remote-iserv";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, nixpkgs-2105, nixpkgs-2111, nixpkgs-2205, nixpkgs-2211, flake-utils, ... }@inputs:
    let
      compiler = "ghc927";
      config = import ./config.nix;
    in {
      inherit config;
      overlay = self.overlays.combined;
      overlays = import ./overlays { sources = inputs; };
      internal = rec {
        nixpkgsArgs = {
          inherit config;
          overlays = [ self.overlay ];
        };

        sources = inputs;

        overlaysOverrideable = import ./overlays;
        # Compatibility with old default.nix
        compat = { checkMaterialization ?
            false # Allows us to easily switch on materialization checking
          , system, sourcesOverride ? { }, ... }@args: rec {
            sources = inputs // sourcesOverride;
            allOverlays = import ./overlays (args // { inherit sources; });
            inherit config;
            # We are overriding 'overlays' and 'nixpkgsArgs' from the
            # flake outputs so that we can incorporate the args passed
            # to the compat layer (e.g. sourcesOverride).
            overlays = [ allOverlays.combined ]
              ++ (if checkMaterialization == true then
                [
                  (final: prev: {
                    haskell-nix = prev.haskell-nix // {
                      checkMaterialization = true;
                    };
                  })
                ]
              else
                [ ]);
            nixpkgsArgs = {
              inherit config overlays;
            };
            pkgs = import nixpkgs
              (nixpkgsArgs // { localSystem = { inherit system; }; });
            pkgs-2105 = import nixpkgs-2105
              (nixpkgsArgs // { localSystem = { inherit system; }; });
            pkgs-2111 = import nixpkgs-2111
              (nixpkgsArgs // { localSystem = { inherit system; }; });
            pkgs-2205 = import nixpkgs-2205
              (nixpkgsArgs // { localSystem = { inherit system; }; });
            pkgs-2211 = import nixpkgs-2211
              (nixpkgsArgs // { localSystem = { inherit system; }; });
            pkgs-unstable = import nixpkgs-unstable
              (nixpkgsArgs // { localSystem = { inherit system; }; });
            hix = import ./hix/default.nix { inherit pkgs; };
          };
      };

      # Note: `nix flake check` evaluates outputs for all platforms, and haskell.nix
      # uses IFD heavily, you have to have the ability to build for all platforms
      # supported by haskell.nix, e.g. with remote builders, in order to check this flake.
      # If you want to run the tests for just your platform, run `./test/tests.sh` or
      # `nix-build -A checks.$PLATFORM`
    } // flake-utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ] (system: rec {
      legacyPackages = (self.internal.compat { inherit system; }).pkgs;
      legacyPackagesUnstable = (self.internal.compat { inherit system; }).pkgs-unstable;

      packages = ((self.internal.compat { inherit system; }).hix).apps;
    }) // {

    # --- Flake Local Nix Configuration ----------------------------
    nixConfig = {
      # This sets the flake to use the IOG nix cache.
      # Nix should ask for permission before using it,
      # but remove it here if you do not want it to.
      extra-substituters = ["https://cache.iog.io"];
      extra-trusted-public-keys = ["hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="];
      allow-import-from-derivation = "true";
    };
  };
}

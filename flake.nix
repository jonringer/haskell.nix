{
  description = "Alternative Haskell Infrastructure for Nixpkgs";

  inputs = {
    nixpkgs.follows = "nixpkgs-unstable";
    nixpkgs-2003 = { url = "github:NixOS/nixpkgs/nixpkgs-20.03-darwin"; };
    nixpkgs-2105 = { url = "github:NixOS/nixpkgs/nixpkgs-21.05-darwin"; };
    nixpkgs-2111 = { url = "github:NixOS/nixpkgs/nixpkgs-21.11-darwin"; };
    nixpkgs-2205 = { url = "github:NixOS/nixpkgs/nixpkgs-22.05-darwin"; };
    nixpkgs-2211 = { url = "github:NixOS/nixpkgs/nixpkgs-22.11-darwin"; };
    nixpkgs-2305 = { url = "github:NixOS/nixpkgs/nixpkgs-23.05-darwin"; };
    nixpkgs-unstable = { url = "github:NixOS/nixpkgs/nixpkgs-unstable"; };
    ghc98X = {
      flake = false;
      url = "git+https://gitlab.haskell.org/ghc/ghc?ref=ghc-9.8&submodules=1";
    };
    ghc99 = {
      flake = false;
      url = "git+https://gitlab.haskell.org/ghc/ghc?submodules=1";
    };
    flake-compat = { url = "github:input-output-hk/flake-compat/hkm/gitlab-fix"; flake = false; };
    flake-utils = { url = "github:hamishmack/flake-utils/hkm/nested-hydraJobs"; };
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

  outputs =
    { self
    , nixpkgs
    , nixpkgs-unstable
    , nixpkgs-2105
    , nixpkgs-2111
    , nixpkgs-2205
    , nixpkgs-2211
    , nixpkgs-2305
    , flake-compat
    , ...
    }@inputs:
    let
      callFlake = import flake-compat;

      compiler = "ghc928";
      config = import ./config.nix;

      inherit (nixpkgs) lib;

      # systems supported by haskell.nix
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      nixpkgsArgs = {
        inherit config;
        overlays = [ self.overlay ];
      };

      forEachSystem = lib.genAttrs systems;
      forEachSystemPkgs = f: forEachSystem (system: f self.legacyPackages.${system});

    in {
      inherit config;
      overlay = self.overlays.combined;
      overlays = import ./overlays { sources = inputs; };

      internal = {
        nixpkgsArgs = {
          inherit config;
          overlays = [ self.overlay ];
        };

        sources = inputs;

        overlaysOverrideable =
          lib.warn
            "Using this attribute is deprecated. Import ${./overlays} directly or use the flake overlays output with override-inut."
            (import ./overlays);

        # Compatibility with old default.nix
        compat =
          lib.warn
            "Using this attribute is deprecated. You can pass the same arguments to ${./default.nix} instead"
            (import ./default.nix);
      };

      legacyPackages = forEachSystem (system:
        import nixpkgs {
          inherit config;
          overlays = [ self.overlay ];
          localSystem = { inherit system; };
        });

      legacyPackagesUnstable = forEachSystem (system:
        import nixpkgs-unstable {
          inherit config;
          overlays = [ self.overlay ];
          localSystem = { inherit system; };
        });

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

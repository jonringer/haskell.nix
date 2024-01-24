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
    nixpkgs-2311 = { url = "github:NixOS/nixpkgs/nixpkgs-23.11-darwin"; };
    # The libsodium bump in 85c6e70b555fe892a049fa3d9dce000dc23a9562 breaks th-dll tests.
    # And later it breaks in th-dll due to some change in the windows libs. We should probably
    # drop unsable.
    nixpkgs-unstable = { url = "github:NixOS/nixpkgs?rev=47585496bcb13fb72e4a90daeea2f434e2501998"; }; # nixpkgs-unstable };
    ghc98X = {
      flake = false;
      url = "git+https://gitlab.haskell.org/ghc/ghc?ref=ghc-9.8&submodules=1";
    };
    ghc99 = {
      flake = false;
      url = "git+https://gitlab.haskell.org/ghc/ghc?submodules=1";
    };
    flake-compat = { url = "github:input-output-hk/flake-compat/hkm/gitlab-fix"; flake = false; };
    "hls-1.10" = { url = "github:haskell/haskell-language-server/1.10.0.0"; flake = false; };
    "hls-2.0" = { url = "github:haskell/haskell-language-server/2.0.0.1"; flake = false; };
    "hls-2.2" = { url = "github:haskell/haskell-language-server/2.2.0.0"; flake = false; };
    "hls-2.3" = { url = "github:haskell/haskell-language-server/2.3.0.0"; flake = false; };
    "hls-2.4" = { url = "github:haskell/haskell-language-server/2.4.0.1"; flake = false; };
    "hls-2.5" = { url = "github:haskell/haskell-language-server/2.5.0.0"; flake = false; };
    "hls-2.6" = { url = "github:haskell/haskell-language-server/2.6.0.0"; flake = false; };
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
    , nixpkgs-2311
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
      };
}

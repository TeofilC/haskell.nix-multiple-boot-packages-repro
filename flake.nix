{
  inputs = {
    nixpkgs = {
      follows = "haskell-nix/nixpkgs";
    };

    haskell-nix = {
      url = "github:input-output-hk/haskell.nix";
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs =
    { self
    , nixpkgs
    , haskell-nix
    , flake-utils
    , ...
    }:
    let
      supportedSystems =
        [ "x86_64-linux" ];

      overlays = [ haskell-nix.overlay ]
        ;

      nixpkgsFor = system: import nixpkgs {
        inherit system;
        inherit (haskell-nix) config;
        inherit overlays;
      };

      projectFor = system:
        let
          pkgs = (nixpkgsFor system);
          gitignore = pkgs.nix-gitignore.gitignoreSourcePure ''
            result
            result-*
            dist-newstyle
            .github
          '';
        in
        pkgs.haskell-nix.cabalProject' {
          src = gitignore ./.;
          compiler-nix-name = "ghc923";
          cabalProjectFileName = "cabal.project";
          modules = [{
          }];
          shell = {
            withHoogle = false;

            exactDeps = true;
          };
        };
    in
    flake-utils.lib.eachSystem supportedSystems (system: rec {
      pkgs = nixpkgsFor system;
      project = projectFor system;
      flake = project.flake { };
      devShell = flake.devShell;
    });
}

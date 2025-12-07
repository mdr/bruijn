{
  description = "Bruijn - A purely functional programming language based on lambda calculus";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # GHC version matching Stack LTS 22.12 (GHC 9.6.4)
        ghcVersion = "ghc96";

        haskellPackages = pkgs.haskell.packages.${ghcVersion}.override {
          overrides = hself: hsuper: {
            # Custom override for bitstring since it's an extra-dep in stack.yaml
            bitstring = pkgs.haskell.lib.dontCheck (hself.callHackageDirect {
              pkg = "bitstring";
              ver = "0.0.0";
              sha256 = "sha256-7ESk+zurwirSmLQo/FY6fA463F+XIX8JY3t/UPWUqTo=";
            } {});
          };
        };

        # Build the Bruijn package
        bruijn = haskellPackages.callCabal2nix "bruijn" ./. { };

      in
      {
        packages = {
          default = bruijn;
          bruijn = bruijn;
        };

        devShells.default = haskellPackages.shellFor {
          packages = p: [ bruijn ];

          buildInputs = with pkgs; [
            haskellPackages.cabal-install
            haskellPackages.ghcid
            haskellPackages.hlint
            # Broogle dependencies
            ripgrep
            jq
            gnused
            gawk
            # Testing
            hyperfine
          ];

          shellHook = ''
            echo "🌟 Bruijn development environment loaded!"
            echo ""
            echo "GHC version: $(ghc --version)"
            echo "Cabal version: $(cabal --version | head -n1)"
            echo ""
            echo "Available commands:"
            echo "  cabal build           - Build the project"
            echo "  cabal run bruijn      - Run the Bruijn interpreter"
            echo "  cabal repl            - Start GHCi REPL"
            echo "  cabal test            - Run tests (if any)"
            echo "  ghcid                 - Run ghcid for auto-recompilation"
            echo "  hlint                 - Haskell linter is available"
            echo ""
            echo "Broogle (standard library search):"
            echo "  ./broogle.sh -t 'a -> a'        - Search by type signature"
            echo "  ./broogle.sh -f 'function_name' - Search by function name"
            echo ""
            echo "Standard library location: ./std/"
          '';
        };
      }
    );
}

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.11";

    # cross-platform convenience
    flake-utils.url = "github:numtide/flake-utils";

    # backwards compatibility with nix-build and nix-shell
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat }:
    # resolve for all platforms in turn
    flake-utils.lib.eachDefaultSystem (system:
      let
        # packages for this system platform
        pkgs = nixpkgs.legacyPackages.${system};

        # control versions
        llvm = pkgs.llvmPackages_19;
        gcc = pkgs.gcc14;

        hook = ''
          export RUBY_API_VERSION="$(ruby -e 'puts RUBY_VERSION.gsub(/\d+$/, "0")')"
          export PATH="$PWD/bin:$PATH"
        '';

        deps = [
          pkgs.libyaml.dev

          # TODO: some gems insist on using `gcc` on Linux, satisfy them for now:
          # - json
          # - protobuf
          # - ruby-prof
          gcc
        ];
      in {
        devShells."ruby-3.4" = llvm.stdenv.mkDerivation {
          name = "devshell";

          buildInputs = [ pkgs.ruby_3_4 ] ++ deps;

          shellHook = hook;
        };

        devShells."ruby-3.3" = llvm.stdenv.mkDerivation {
          name = "devshell";

          buildInputs = [ pkgs.ruby_3_3 ] ++ deps;

          shellHook = hook;
        };

        devShells."ruby-3.2" = llvm.stdenv.mkDerivation {
          name = "devshell";

          buildInputs = [ pkgs.ruby_3_2 ] ++ deps;

          shellHook = hook;
        };

        devShells."ruby-3.1" = llvm.stdenv.mkDerivation {
          name = "devshell";

          buildInputs = [ pkgs.ruby_3_1 ] ++ deps;

          shellHook = hook;
        };

        # convenience aliases
        devShells.ruby_3_1 = self.devShells.${system}."ruby-3.1";
        devShells.ruby_3_2 = self.devShells.${system}."ruby-3.2";
        devShells.ruby_3_3 = self.devShells.${system}."ruby-3.3";
        devShells.ruby_3_4 = self.devShells.${system}."ruby-3.4";

        # default to latest
        devShells.default = self.devShells.${system}."ruby-3.4";
      }
    );
}

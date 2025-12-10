{
  description = "Nix flake for developing and serving the URC KAIST docs";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        hugoPkg = pkgs.hugo;

        serveDocs = pkgs.writeShellApplication {
          name = "serve-docs";
          runtimeInputs = [ hugoPkg ];
          text = ''
            PORT="''${PORT:-1313}"
            # Expose drafts and future-dated pages while iterating locally
            exec hugo server \
              --bind 0.0.0.0 \
              --port "$PORT" \
              --buildDrafts \
              --buildFuture \
              --disableFastRender
          '';
        };
      in
      {
        packages = {
          default = serveDocs;
          serve = serveDocs;
        };

        apps = {
          default = {
            type = "app";
            program = "${serveDocs}/bin/serve-docs";
          };
          serve = {
            type = "app";
            program = "${serveDocs}/bin/serve-docs";
          };
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.hugo
            pkgs.git
          ];
        };

        formatter = pkgs.nixfmt-rfc-style;
      });
}

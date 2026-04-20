{
  description = "Lefthook-compatible nix no-embedded-shell check";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "x86_64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems =
        f: nixpkgs.lib.genAttrs supportedSystems (system: f nixpkgs.legacyPackages.${system});
      scannerScript = ./scan-nix-no-embedded-shell.sh;
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.writeShellApplication {
          name = "lefthook-nix-no-embedded-shell";
          text = ''
            SCANNER="${scannerScript}"
          ''
          + builtins.readFile ./lefthook-nix-no-embedded-shell.sh;
        };
      });

      devShells = forAllSystems (
        pkgs:
        let
          src-git-conflict-markers = builtins.fetchGit {
            url = "https://github.com/pr0d1r2/nix-lefthook-git-conflict-markers";
            ref = "main";
          };
          src-git-no-local-paths = builtins.fetchGit {
            url = "https://github.com/pr0d1r2/nix-lefthook-git-no-local-paths";
            ref = "main";
          };
          src-missing-final-newline = builtins.fetchGit {
            url = "https://github.com/pr0d1r2/nix-lefthook-missing-final-newline";
            ref = "main";
          };
          src-trailing-whitespace = builtins.fetchGit {
            url = "https://github.com/pr0d1r2/nix-lefthook-trailing-whitespace";
            ref = "main";
          };
          pkg-git-conflict-markers = pkgs.writeShellApplication {
            name = "lefthook-git-conflict-markers";
            runtimeInputs = [ pkgs.gnugrep ];
            text = builtins.readFile "${src-git-conflict-markers}/lefthook-git-conflict-markers.sh";
          };
          pkg-git-no-local-paths = pkgs.writeShellApplication {
            name = "lefthook-git-no-local-paths";
            runtimeInputs = [ pkgs.gnugrep ];
            text = builtins.readFile "${src-git-no-local-paths}/lefthook-git-no-local-paths.sh";
          };
          pkg-missing-final-newline = pkgs.writeShellApplication {
            name = "lefthook-missing-final-newline";
            text = builtins.readFile "${src-missing-final-newline}/lefthook-missing-final-newline.sh";
          };
          pkg-trailing-whitespace = pkgs.writeShellApplication {
            name = "lefthook-trailing-whitespace";
            runtimeInputs = [ pkgs.gnugrep ];
            text = builtins.readFile "${src-trailing-whitespace}/lefthook-trailing-whitespace.sh";
          };
          batsWithLibs = pkgs.bats.withLibraries (p: [
            p.bats-support
            p.bats-assert
            p.bats-file
          ]);
        in
        {
          default = pkgs.mkShell {
            packages = [
              self.packages.${pkgs.stdenv.hostPlatform.system}.default
              pkg-git-conflict-markers
              pkg-git-no-local-paths
              pkg-missing-final-newline
              pkg-trailing-whitespace
              batsWithLibs
              pkgs.coreutils
              pkgs.deadnix
              pkgs.editorconfig-checker
              pkgs.git
              pkgs.lefthook
              pkgs.nix
              pkgs.nixfmt
              pkgs.parallel
              pkgs.shellcheck
              pkgs.shfmt
              pkgs.statix
              pkgs.typos
              pkgs.yamllint
            ];
            shellHook = builtins.replaceStrings [ "@BATS_LIB_PATH@" ] [ "${batsWithLibs}" ] (
              builtins.readFile ./dev.sh
            );
          };
        }
      );
    };
}

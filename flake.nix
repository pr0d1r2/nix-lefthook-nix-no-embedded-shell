{
  description = "CHANGEME";

  nixConfig = {
    extra-substituters = [ "https://pr0d1r2.cachix.org" ];
    extra-trusted-public-keys = [ "pr0d1r2.cachix.org-1:NfWjbhgAj41byXhCKiaE+av3Vnphm1fTezHXEGsiQIM=" ];
  };

  inputs = {
    nixpkgs-lock.url = "github:pr0d1r2/nixpkgs-lock";
    nixpkgs.follows = "nixpkgs-lock/nixpkgs";

    set-and-setting = {
      url = "github:pr0d1r2/set-and-setting";
      inputs.nixpkgs.follows = "nixpkgs-lock/nixpkgs";
      inputs.nixpkgs-lock.follows = "nixpkgs-lock";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      set-and-setting,
      ...
    }:
    set-and-setting.lib.mkConsumerFlake {
      inherit self nixpkgs set-and-setting;
      fragments = [
        "base"
        "nix"
        "shell"
        "ascii"
        "markdown"
        "yaml"
      ];
      src = ./.;
      extraPackages = pkgs: {
        default = pkgs.writeShellApplication {
          name = "lefthook-nix-no-embedded-shell";
          text = ''
            SCANNER="${./scan-nix-no-embedded-shell.sh}"
          ''
          + builtins.readFile ./lefthook-nix-no-embedded-shell.sh;
        };
      };
      extraChecks = pkgs: {
        unit-tests =
          pkgs.runCommand "unit-tests"
            {
              nativeBuildInputs = [
                (pkgs.bats.withLibraries (libraries: [
                  libraries.bats-assert
                  libraries.bats-file
                  libraries.bats-support
                ]))
                pkgs.git
                self.packages.${pkgs.stdenv.hostPlatform.system}.default
              ];
            }
            ''
              cd ${./.}
              bats tests/unit/
              touch "$out"
            '';
      };
    };
}

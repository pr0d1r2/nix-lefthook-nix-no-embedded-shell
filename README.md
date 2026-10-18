# nix-lefthook-nix-no-embedded-shell

<!-- hallucinogen:autonomy-disclaimer start -->
> Read [LLM-DISCLAIMER](docs/LLM-DISCLAIMER.md) first. This repository is
> tended by an autonomous loop, and that file says what the loop may do here,
> what it may not, and what to check before trusting anything in this tree.
<!-- hallucinogen:autonomy-disclaimer end -->

[![CI](https://github.com/pr0d1r2/nix-lefthook-nix-no-embedded-shell/actions/workflows/ci.yml/badge.svg)](https://github.com/pr0d1r2/nix-lefthook-nix-no-embedded-shell/actions/workflows/ci.yml) [![NixOS 26.05](https://img.shields.io/badge/NixOS-26.05-blue.svg?logo=nixos)](https://nixos.org)

> This code is LLM-generated and validated through an automated integration process using [lefthook](https://github.com/evilmartians/lefthook) git hooks, [bats](https://github.com/bats-core/bats-core) unit tests, and GitHub Actions CI.

Lefthook-compatible [nix no-embedded-shell](https://nixos.org/) wrapper, packaged as a Nix flake.

Detects embedded shell code inside `''...'''` blocks in `.nix` files. Supports an allowlist file (`.nix-embedded-shell-allowlist`) for grandfathered files. Exits 0 when no matching files are found.

## Architecture

```mermaid
flowchart LR
  consumer["consumer lefthook.yml"] -->|"remotes"| remote["lefthook-remote.yml"]
  remote -->|"pre-commit: *.nix → {staged_files}"| lefthook_nix_no_embedded_shell["lefthook-nix-no-embedded-shell"]
  remote -->|"pre-push: *.nix → {push_files}"| lefthook_nix_no_embedded_shell["lefthook-nix-no-embedded-shell"]
  lefthook_nix_no_embedded_shell -->|"runs"| tool["nix no-embedded-shell"]
  lefthook_nix_no_embedded_shell -->|"exit status"| consumer
```

## Usage

### Option A: Lefthook remote (recommended)

Add to your `lefthook.yml` — no flake input needed, just the wrapper binary in your devShell:

```yaml
remotes:
  - git_url: https://github.com/pr0d1r2/nix-lefthook-nix-no-embedded-shell
    ref: main
    configs:
      - lefthook-remote.yml
```

### Option B: Flake input

Add as a flake input:

```nix
inputs.nix-lefthook-nix-no-embedded-shell = {
  url = "github:pr0d1r2/nix-lefthook-nix-no-embedded-shell";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Add to your devShell:

```nix
nix-lefthook-nix-no-embedded-shell.packages.${pkgs.stdenv.hostPlatform.system}.default
```

Add to `lefthook.yml`:

```yaml
pre-commit:
  commands:
    nix-no-embedded-shell:
      glob: "*.nix"
      run: timeout ${LEFTHOOK_NIX_NO_EMBEDDED_SHELL_TIMEOUT:-30} lefthook-nix-no-embedded-shell {staged_files}
```

## Self-linting

> **Note:** This repo uses raw `statix check` and `deadnix --fail` commands
> in its own lefthook config instead of the flake-wrapped versions. This
> avoids circular flake dependencies — the nix-check repos and the base
> linter repos form a dependency cycle if they reference each other as flake
> inputs. Leaf repos that consume these checks do not have this limitation
> and use the wrapped versions normally.

### Configuring timeout

The default timeout is 30 seconds. Override per-repo via environment variable:

```bash
export LEFTHOOK_NIX_NO_EMBEDDED_SHELL_TIMEOUT=60
```

## Development

The repo includes an `.envrc` for [direnv](https://direnv.net/) — entering the directory automatically loads the devShell with all dependencies:

```bash
cd nix-lefthook-nix-no-embedded-shell  # direnv loads the flake
bats tests/unit/
```

If not using direnv, enter the shell manually:

```bash
nix develop
bats tests/unit/
```

### Development architecture

```mermaid
flowchart LR
  envrc[".envrc"] -->|"use flake"| flake["flake.nix"]
  flake -->|"mkConsumerFlake"| sas["set-and-setting"]
  flake -->|"devShell"| shell["dev shell"]
  shell -->|"on entry"| devsh["dev.sh"]
  sas -->|"assembled hooks"| lh["lefthook.yml"]
  repo["lefthook-repo.yml"] --> lh
  lh -->|"pre-commit / pre-push"| checks["linters, bats, nix flake check"]
  ci[".github/workflows/ci.yml"] -->|"guardrails.yml"| checks
```

## License

MIT

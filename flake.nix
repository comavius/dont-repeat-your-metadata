{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    rust-overlay,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      # Reading Cargo.toml and parsing it.
      cargo-toml = builtins.fromTOML (builtins.readFile ./Cargo.toml);

      pkgs = import nixpkgs {
        inherit system;
        overlays = [rust-overlay.overlays.default];
      };
      toolchain = pkgs.rust-bin.stable.latest.default.override {
        extensions = [
          "rust-src"
        ];
      };
      rustPlatform = pkgs.makeRustPlatform {
        cargo = toolchain;
        rustc = toolchain;
      };
    in {
      packages.default = rustPlatform.buildRustPackage {
        # `pname` and `version` are read from Cargo.toml.
        pname = cargo-toml.package.name;
        version = cargo-toml.package.version;

        src = ./.;
        cargoLock = {
          lockFile = ./Cargo.lock;
        };

        # Also, all metadata is written in `Cargo.toml`!
        meta = with cargo-toml.package; {
          inherit description license homepage;
          maintainers = authors;
        };
      };

      devShells.default = pkgs.mkShell {
        buildInputs = [toolchain];
      };
      formatter = pkgs.alejandra;
    });
}

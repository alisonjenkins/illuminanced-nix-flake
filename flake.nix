{
  description = "NixOS packages for illuminanced - Ambient Light Sensor Daemon for Linux";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      pkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
        }
      );
    in
    {
      overlays.default = final: prev: {
        illuminanced = final.callPackage ./illuminanced {};
      };

      legacyPackages = forAllSystems (system:
        (import ./default.nix) pkgsFor.${system}
      );

      packages = forAllSystems (system:
        (import ./default.nix) pkgsFor.${system}
      );

      homeManagerModules = {
        illuminanced = import ./home-manager-module.nix;
        default = self.homeManagerModules.illuminanced;
      };
    };
}

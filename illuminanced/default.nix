{ pkgs, lib }:
let
  src = (import ../source { inherit pkgs; });
in
pkgs.rustPlatform.buildRustPackage {
  pname = "illuminanced";
  version = "0.1.2";
  doCheck = false;
  cargoHash = "sha256-kPWoQ6rE4wBjmqQLNPY4UWJt/AOgr+eVKY0ZK7B4K1A=";

  src = src;

  meta = {
    description = "Ambient Light Sensor Daemon for Linux";
    homepage = "https://github.com/mikhail-m1/illuminanced";
    license = lib.licenses.gpl3;
    platforms = lib.platforms.linux;
    maintainers = [ ];
  };
}

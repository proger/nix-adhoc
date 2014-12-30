{ pkgs, lib, config, ... }:
with lib;

let
  stub = mkOption {
    type = types.attrsOf types.unspecified;
  };
in
{
  imports = [
    ./user.nix
    ./supervisord.nix
    ./systemd.nix

    <nixpkgs/nixos/modules/misc/nixpkgs.nix>

    <nixpkgs/nixos/modules/config/users-groups.nix>
    <nixpkgs/nixos/modules/misc/assertions.nix>
#    <nixpkgs/nixos/modules/misc/ids.nix>
#    <nixpkgs/nixos/modules/config/timezone.nix>
  ];

  options = { 
    nix-adhoc.name = mkOption {
      default = "nix-adhoc-service";
      type = types.str;
    };

    services.nginx = stub;
    system.activationScripts = stub;
    system.build = stub;

    environment.etc = stub;
    environment.systemPackages = mkOption {
      default = [];
      description = "Packages to be put in the system profile.";
    };
    environment.umask = mkOption { default = "002"; };
  };

  config = {
    nixpkgs.system = "x86_64-linux";

    system.build.toplevel = pkgs.stdenv.mkDerivation rec {
      name = config.nix-adhoc.name;
      phases = [ "installPhase" ];

      installPhase = ''
          mkdir -p $out/bin/
          ln -s ${config.supervisord.bin}/bin/supervisord $out/bin/${name}-supervisord
          ln -s ${config.supervisord.bin}/bin/supervisorctl $out/bin/${name}-supervisorctl
      '';
      passthru.config = config;
    };
  };
}

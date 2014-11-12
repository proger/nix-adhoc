{ lib, config, ... }:
with lib;

let
  stub = mkOption {
    type = types.attrsOf types.unspecified;
  };

  baseModules = [
    ./user.nix
    ./supervisord.nix
    ./systemd.nix

    <nixpkgs/nixos/modules/misc/nixpkgs.nix>

    ({ config, pkgs, ... }: {
     options = { 
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
          name = "entrypoint";
          phases = [ "installPhase" ];

          installPhase = ''
              mkdir -p $out/bin/
              ln -s ${config.supervisord.bin}/bin/supervisord $out/bin/${name}-start-services
              ln -s ${config.supervisord.bin}/bin/supervisorctl $out/bin/${name}-control-services
          '';
          passthru.config = config;
        };
     };
    })

    <nixpkgs/nixos/modules/config/users-groups.nix>
    <nixpkgs/nixos/modules/misc/assertions.nix>
#    <nixpkgs/nixos/modules/misc/ids.nix>
#    <nixpkgs/nixos/modules/config/timezone.nix>
  ];
  pkgs = import <nixpkgs> {};
in {
  options = {
    images = mkOption {
      type = types.attrsOf (types.submodule baseModules);
      default = {};
    };

    misc = stub;
  };

  config = {
    misc = {
      images-map = let nativePkgs = import pkgs.path { system = "x86_64-linux"; }; in
        nativePkgs.writeText "images-map"
        (builtins.toJSON (lib.mapAttrs (n: v: ''${v.system.build.toplevel}'') config.images));
    };
  };
}

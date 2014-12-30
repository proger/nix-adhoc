{ configuration
, system ? "x86_64-linux"
}:

let
  eval-config = import <nixpkgs/nixos/lib/eval-config.nix>;
  baseModules = [ ./nixos.nix ];

  eval = eval-config {
    check = false;
    inherit system baseModules;
    modules = [ configuration ];
  };

  inherit (eval) pkgs;
in
{
  inherit (eval) config options;

  system = eval.config.system.build.toplevel;
}

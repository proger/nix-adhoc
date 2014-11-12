{ exprs }:

let
  lib = import <nixpkgs/lib>;

  eval = lib.evalModules {
    modules = [ ./nixos.nix rec {
      _file = ./eval-image.nix;
      key = _file;
      config.__internal = {
        check = false;
        args.pkgs = import <nixpkgs> { system = "x86_64-linux"; };
      };
    } ] ++ (if lib.isList exprs then exprs else [ exprs ]);
  };
in eval.config // { inherit eval; inherit __nixPath; }


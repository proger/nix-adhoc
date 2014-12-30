{ lib, config, ... }:
let
  pkgs-native = import <nixpkgs> {};
  defnix = <defnix>;
in
{
  imports = [
    ./ipsec-wrapper.nix
  ];
  config = {
    nix-adhoc.name = "ipsec";
    defnixos.ca = ./ca.crt;
    defnixos.cert-archive = "/etc/x509/strongswan.p12";
  };
}

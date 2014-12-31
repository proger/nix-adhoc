{ lib, config, pkgs, ... }:
{
  imports = [
    <nixpkgs/nixos/modules/services/networking/strongswan.nix>
  ];
  config = {
    nix-adhoc.name = "ipsec";

    systemd.services.strongswan = {
      description = "strongSwan IPSec Service";
      wantedBy = [ "multi-user.target" ];
      path = with pkgs; [ kmod iproute iptables utillinux ]; # XXX Linux
      wants = [ "keys.target" ];
      after = [ "network.target" "keys.target" ];
      environment = {
        STRONGSWAN_CONF = "/dev/null";
      };
      serviceConfig = {
        ExecStart  = "${pkgs.strongswan}/sbin/ipsec start --nofork";
      };
    };
  };
}

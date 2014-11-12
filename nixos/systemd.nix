{ pkgs, lib, config, ... }:
  with lib;
  with import <nixpkgs/nixos/modules/system/boot/systemd-unit-options.nix> {
    inherit config;
    inherit (pkgs) lib;
  };
let
  services = config.systemd.services;

  isOneShot = cfg: hasAttr "Type" cfg.serviceConfig && cfg.serviceConfig.Type == "oneshot";

  runServices = filterAttrs (name: cfg: !(isOneShot cfg)) services;

  oneShotServices = filterAttrs (name: cfg: isOneShot cfg) services;

  filterCommand = cmd:
    let
      filtered = substring 1 (stringLength cmd -2) cmd;
      splitted = pkgs.lib.splitString (" " + substring 0 0 filtered) filtered;
    in if eqStrings (substring 0 1 cmd) "@" then
        traceVal (head splitted) + concatStringsSep " " (drop 2 splitted)
       else cmd;

  configToCommand = name: cfg: ''
      #!/bin/sh -e
      ${if hasAttr "preStart" cfg then cfg.preStart else ""}
      ${if hasAttr "ExecStart" cfg.serviceConfig then
          filterCommand cfg.serviceConfig.ExecStart
        else if hasAttr "script" cfg then
          (pkgs.writeScript "${name}-start.sh" cfg.script)
        else
          "echo"
      } &
      export MAINPID=$!
      ${if hasAttr "postStart" cfg then cfg.postStart else ""}
      wait
      '';

in {

  options = {
    systemd.services = mkOption {
      default = {};
      type = types.attrsOf types.optionSet;
      options = [ serviceOptions ];
    }; # TODO make more specific

    systemd.globalEnvironment = mkOption {
      default = {};
    };

    services.dataPrefix = mkOption {
      default = "/var";
      type = types.path;
      description = '''';
    };
  };

  config = {
    userNix.startScripts."1-systemd-oneshot" = concatMapStrings (name: "${configToCommand name (getAttr name oneShotServices)}\n") (attrNames oneShotServices);

    supervisord.services = listToAttrs (map (name:
      let
        cfg = getAttr name services;
      in
        {
          name = name;
          value = {
            command = pkgs.writeScript "${name}-run" (configToCommand name cfg);
            environment = cfg.environment // config.systemd.globalEnvironment;
            path = cfg.path;
            stopsignal = if hasAttr "KillSignal" cfg.serviceConfig then
              substring 3 (stringLength cfg.serviceConfig.KillSignal) cfg.serviceConfig.KillSignal
            else "TERM";
            pidfile = if hasAttr "PIDFile" cfg.serviceConfig then cfg.serviceConfig.PIDFile else null;
          };
        }
      ) (attrNames (filterAttrs (n: v: v.enable) runServices)));
  };
}

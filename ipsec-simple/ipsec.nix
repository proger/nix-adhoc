let
  pkgs = import <nixpkgs> { system = "x86_64-linux"; };
  inherit (pkgs) lib;
in
rec {
  strongswan-conf = pkgs.writeText "strongswan.conf" ''
    charon {
      retry_initiate_interval = 30
      plugins {
        stroke {
          secrets_file = ${./ipsec.secrets}
        }
      }
    }
    starter {
      config_file = ${./ipsec.conf}
    }
  '';

  ipsec = let
      path = with pkgs; [ kmod iproute iptables utillinux coreutils strongswan gnugrep ];
    in pkgs.writeScript "ipsec" ''
      #!${pkgs.bash}/bin/bash
      env PATH=${lib.makeSearchPath "bin" path}:${lib.makeSearchPath "sbin" path} \
          STRONGSWAN_CONF=${strongswan-conf} \
          ${pkgs.strongswan}/libexec/ipsec/starter --nofork --debug
    '';

  standalone = mk-supervisor {
    name = "ipsec";
    command = "${ipsec}";
    ln-extra = [ "${pkgs.strongswan}/bin/ipsec" ];
  };

  conf-tunnel = ''
    sysctl net.ipv4.ip_forward=1
    ip addr add 169.254.251.22/30 dev eth0
    ip ro del 10.15.0.0/24 via 192.168.100.1 table 220
    ip ro add 10.15.0.0/24 via 169.254.251.21 table 220
  '';

  conf-nodes = ''
    ip ro add 10.15.0.0/24 via 172.16.2.36
  '';

  mk-supervisor =
    { name, command, state-dir ? "/tmp/${name}", directory ? "/var/empty", ln-extra ? [] }:
    with lib;
    let
      inherit (pkgs.pythonPackages) supervisor;
      config = pkgs.writeText "${name}.conf" ''
        [supervisord]
        pidfile=${state-dir}/run/supervisord.pid
        childlogdir=${state-dir}/log/
        logfile=${state-dir}/log/supervisord.log

        [supervisorctl]
        serverurl = unix://${state-dir}/ctl.sock

        [program:${name}]
        command=${command}
        directory=${directory}
        redirect_stderr=true
        stopasgroup=true
      '';

      supervisord-wrapper = pkgs.writeScript "supervisord-wrapper" ''
        #!/usr/bin/env bash
        mkdir -p "${state-dir}"/{run,log}
        export PATH="${pkgs.coreutils}/bin"
        exec ${supervisor}/bin/supervisord -c ${config} -j ${state-dir}/run/supervisord.pid -d ${state-dir} -q ${state-dir}/log/ -l ${state-dir}/log/supervisord.log "$@"
      '';

      supervisorctl-wrapper = pkgs.writeScript "supervisorctl-wrapper" ''
        #!/usr/bin/env bash
        exec ${supervisor}/bin/supervisorctl -c ${config} "$@"
      '';
    in 
      pkgs.runCommand name {} ''
        #!${pkgs.bash}/bin/bash
        mkdir -p $out/bin/
        ln -s ${supervisord-wrapper} $out/bin/${name}-supervisord
        ln -s ${supervisorctl-wrapper} $out/bin/${name}-supervisorctl
        ${concatStringsSep "\n" (map (x: "ln -s ${x} $out/bin/") ln-extra)}
      '';
}

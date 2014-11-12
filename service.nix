{ pkgs, ... }:
{ name ? "supervised-program"
, command ? let script = pkgs.writeScript "${name}" ''
    #!/usr/bin/env bash
    echo hello
    sleep 10
    echo bye
  ''; in "${script}"
, state-dir ? "/var/tmp/${name}"
}:

with pkgs.lib;

let inherit (pkgs.pythonPackages) supervisor; in
rec {
  config = pkgs.writeText "supervisord.conf" ''
    [supervisord]
    pidfile=${state-dir}/run/supervisord.pid
    childlogdir=${state-dir}/log/
    logfile=${state-dir}/log/supervisord.log

    [supervisorctl]
    serverurl = unix:///${state-dir}/run/supervisord.sock

    [unix_http_server]
    file = ${state-dir}/run/supervisord.sock

    [rpcinterface:supervisor]
    supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

    [program:${name}]
    command=${command}
    directory=${state-dir}
    redirect_stderr=true
    startsecs=1
    stopsignal=TERM
    stopasgroup=true
  '';

  supervisord-wrapper = pkgs.writeScript "supervisord-wrapper" ''
    #!${pkgs.bash}/bin/bash
    extraFlags=""
    export STATEDIR=${state-dir}
    mkdir -p "$STATEDIR"/{run,log}
    export PATH="${pkgs.coreutils}/bin"
    ${supervisor}/bin/supervisord -c ${config} -j $STATEDIR/run/supervisord.pid -d $STATEDIR -q $STATEDIR/log/ -l $STATEDIR/log/supervisord.log $@
  '';

  supervisorctl-wrapper = pkgs.writeScript "supervisorctl-wrapper" ''
    #!${pkgs.bash}/bin/bash
    ${supervisor}/bin/supervisorctl -c ${config} $@
  '';

  supervisor-env = pkgs.stdenv.mkDerivation {
    name = "${name}-main";
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin/
      ln -sf ${supervisord-wrapper} $out/bin/supervisord
      ln -sf ${supervisorctl-wrapper} $out/bin/supervisorctl
    '';
  };
}
  

{ pkgs ? import <nixpkgs> { system = "x86_64-linux"; }, ... }:
with pkgs.lib;

let
  sproxyOrig = (import <sproxy> { inherit pkgs; }).buildExecutableOnly;

  sproxy = pkgs.stdenv.mkDerivation {
    name = "${sproxyOrig.name}-binonly";
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin
      install ${sproxyOrig}/bin/.sproxy-wrapped $out/bin/sproxy
      source ${pkgs.makeWrapper}/nix-support/setup-hook
      wrapProgram $out/bin/sproxy --prefix LD_LIBRARY_PATH : ${pkgs.stdenv.gcc.gcc}/lib64
    '';
  };

  auth-token-key = "${<sproxy/config/auth_token_key.example>}";
  client-secret = "${<sproxy/config/auth_token_key.example>}";
  ssl-key = "${<sproxy/config/server.key.example>}";
  ssl-certs = "${<sproxy/config/server.crt.example>}";

  sproxy-config = pkgs.writeText "sproxy-TEST.conf" ''
    log_level: info
    redirect_http_to_https: no
    client_id: 737541209123-i2jep908cck0dm71468kvgqfcuagkekj.apps.googleusercontent.com
    database: "unused"
    backend_address: "127.0.0.1"
    cookie_name: sproxy-TEST
    backend_port: 80
    cookie_domain: example.com
    listen: 8443
    client_secret: ${client-secret}
    auth_token_key: ${auth-token-key}
    ssl_key: ${ssl-key}
    ssl_certs: ${ssl-certs}
  '';

  service = import ./service.nix { inherit pkgs; } {
    name = "sproxy-TEST";
    command = "${sproxy}/bin/sproxy --config=${sproxy-config}";
  };
in
{
  sproxy = service.supervisor-env;
}

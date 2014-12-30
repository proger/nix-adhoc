## nix-adhoc

Hacks to make nix module system-based services (and beyond) runnable on non-NixOS systems.

* nixos module system-based stuff is in `nixos/`
* totally standalone stuff is in `./` (start at `sproxy.nix`)

### Bootstrapping

#### CentOS

```console
% upcast infra test/infra.nix > test/ssh_config
% cat nix-install | ssh -F test/ssh_config centos bash -
```

### Pushing the service to a system

```console
% upcast install -t $(awk '/HostName/{print $2}' test/ssh_config) \
    -f hydra \
    -p /nix/var/nix/profiles/sproxy-defnix \
    $(upcast build-remote -t hydra.zalora.com -A sproxy sproxy.nix)
% ssh -F test/ssh_config /nix/var/nix/profiles/sproxy-defnix/bin/supervisord
```

### IPsec service

```console
% env NIX_PATH=$PWD/nix-path nix-build ipsec/
% upcast install -t target -f hydra -p /nix/var/nix/profiles/ipsec /nix/store/xxx-ipsec
```

### Acknowledgements

`systemd` -> `supervisord` stub and some ideas have been taken from [nix-rehash](https://github.com/kiberpipa/nix-rehash).
Some code was taken from [Upcast](https://github.com/zalora/upcast) which in turn inherited it from [NixOps](https://github.com/nixos/nixops).

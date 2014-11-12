## nix-adhoc

Hacks to make nix module system-based services runnable on non-NixOS systems.

### Bootstrapping

#### CentOS

```console
% upcast infra test/infra.nix > test/ssh_config
% cat nix-install | ssh -F test/ssh_config centos bash -
```

### Pushing the service to a system

```
% upcast build-remote -t hydra.zalora.com -A misc.images-map target-service.nix
% upcast install -t $(awk '/HostName/{print $2}' test/ssh_config) \
    -f hydra \
    -p /nix/var/nix/profiles/target-service \
    /nix/store/mqlniv4kfr5py348whya212hmalam411-entrypoint
% ssh -F test/ssh_config /nix/var/nix/profiles/target-service/bin/entrypoint-start-services -n
```

### Acknowledgements

`systemd` -> `supervisord` stub and some ideas have been taken from [nix-rehash](https://github.com/kiberpipa/nix-rehash).
Some code was taken from [Upcast](https://github.com/zalora/upcast) which in turn inherited it from [NixOps](https://github.com/nixos/nixops).

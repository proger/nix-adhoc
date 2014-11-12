## using nix services on non-NixOS systems

#### CentOS

```console
upcast infra test/infra.nix > test/ssh_config
cat nix-install | ssh -F test/ssh_config centos bash -
```

#### Ubuntu

##### unlocking root:

```console
ssh ubuntu -l ubuntu sudo passwd -u root
ssh ubuntu -l ubuntu sudo cp .ssh/authorized_keys /root/.ssh
ssh ubuntu -l ubuntu sudo chmod 600 /root/.ssh/authorized_keys
ssh ubuntu -l ubuntu sudo chown root:root /root/.ssh/authorized_keys
```


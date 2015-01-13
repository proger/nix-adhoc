## ipsec sample

Deploying (`<nixpkgs>` should point to `release-14.12` branch):

```console
% upcast build-remote -t hydra -A standalone ipsec.nix \
    | xargs -n1t upcast install -t target -f hydra -p /srv/ipsec
```

Starting IPsec tunnel:

```console
% ssh target -t sudo /src/ipsec/bin/ipsec-supervisord
```

Monitoring:

```
% ssh target -t sudo watch /srv/ipsec/bin/ipsec statusall
```

Configuring VPN (proper routing):

```
eval printf $(nix-instantiate --eval -A conf-tunnel ipsec.nix) | ssh target sudo -i bash -
```

Configuring other machines' routing (just `node1` here):

```
eval printf $(nix-instantiate --eval -A conf-nodes ipsec.nix) | ssh node1 sudo -i bash -
```

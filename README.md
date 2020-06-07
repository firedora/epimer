# epimer

Epimer is a IKEv2 VPN server based on [Alpine](https://hub.docker.com/_/alpine).

## How to use this image

Starting a epimer instance is simple:

```sh
docker run \
    --restart=always \
    --detach \
    --privileged \
    --sysctl net.ipv4.ip_forward=1 \
    --sysctl net.ipv4.conf.all.accept_redirects=0 \
    --sysctl net.ipv4.conf.all.send_redirects=0 \
    --sysctl net.ipv4.ip_no_pmtu_disc=1 \
    --volume=/lib/modules:/lib/modules \
    --volume=/etc/epimer/pki:/etc/epimer/pki \
    --publish=500:500/udp \
    --publish=4500:4500/udp \
    --env HOST="<your-servder-ip>" \
    --name epimer kepuro:epimer
```

Adding a new user:

```sh
docker exec epimer vpnctl user add <username> <password>
```

Generating CA certificate:

```sh
docker exec epimer vpnctl cert create --type=ca
```

Generating server certificate:

```sh
docker exec epimer vpnctl cert create --type=server
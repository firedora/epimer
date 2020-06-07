FROM alpine:latest

ENV STRONGSWAN_RELEASE=https://download.strongswan.org/strongswan.tar.bz2 \
    PKIDIR="/etc/epimer/pki" \
    ORGANIZATION="Kepuro" \
    CA_NAME="Epimer IKEv2 VPN Root CA"

VOLUME $PKIDIR

WORKDIR /root/epimer

COPY . .

RUN apk --no-cache add bash bash-doc bash-completion
RUN chmod +x scripts/install.sh
RUN scripts/install.sh

EXPOSE 500:500/udp
EXPOSE 4500:4500/udp

CMD scripts/entry.sh

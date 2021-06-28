#! /usr/bin/env bash

PUBLIC_KEY='ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGYxykQEihNO5jv/gO2hQaf5wcWe2zg1Fa/s+QbqPLA58wA0jXczYv7QYjTqsVXl/BPwhVbanL3Obec0SzdFk5eYiiwbNjzcGEsDYNIGBYsf/KkjMYxhoDfwxZCgeOjU3fJ4140PMleTv2YdGbqINxGFSCFQvBxoIAwyCHU4Y1xCha0+/S0L5DsiDjKlHlWo4FKRQrv6pcX5kCk95mvnc+h8zkX1liz6MbSQG5t5kggfFhMaaMLAVzmGn1fsICn1IGp7eqx5CWThjF07P5p75LyD9hgP9KciLEdP4OBuBBxHjKVLf/qmv7gy3X37Ywb4TSYNrWXTOuskYDuavRaVZL'

echo "Copyright 2019 (c) TARGET S.A."
echo
echo
echo "1 – Agrego FQDN al archivo /etc/hosts"

# Override /etc/hosts by prepending FQDN
cat /etc/hosts | sed -e "1i 127.0.0.1  $(hostname -s).CONWAYSTORE.LOCAL  $(hostname -s)" -e \
"/127.0.0.1/d" | tee /etc/hosts

echo "2 – Elimino usuario sdp *solo si* existe"

userdel -r sdp > 2&>/dev/null

echo "3 – Creo usuario sdp *exclusivo* para AE scan"

useradd -m sdp && \
su sdp -c "mkdir ~/.ssh/; echo $PUBLIC_KEY >> ~/.ssh/authorized_keys" && \
# Upon success...
exit 1

echo
echo "Adios!"

# All done!
exit

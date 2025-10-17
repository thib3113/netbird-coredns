#!/bin/sh
set -e

echo "Starting CoreDNS in the background..."
coredns -conf /etc/coredns/Corefile &

echo "Executing original Netbird entrypoint..."
exec /usr/local/bin/netbird-entrypoint.sh "$@"

#!/bin/bash -e

[[ "$EUID" -ne 0 ]] && { echo "Please run as root!"; exit; }

ovs-vsctl add-port br-int port1 -- \
  set interface port1 \
    type=internal \
    mac='["c0:ff:ee:00:00:11"]' \
    external_ids:iface-id=port1

ovs-vsctl show

ip netns add vm1
ip link set netns vm1 port1
ip -n vm1 addr add 127.0.0.1/8 dev lo
ip -n vm1 link set lo up
ip netns exec vm1 dhclient -v -i port1 --no-pid
ip netns exec vm1 ip a show port1

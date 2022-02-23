#!/bin/bash -e

[[ "$EUID" -ne 0 ]] && { echo "Please run as root!"; exit; }

ovs-vsctl add-port br-int port2 -- \
  set interface port2 \
    type=internal \
    mac='["c0:ff:ee:00:00:12"]' \
    external_ids:iface-id=port2

ip netns add vm2
ip link set netns vm2 port2
ip -n vm2 addr add 127.0.0.1/8 dev lo
ip -n vm2 link set lo up  
ip netns exec vm2 dhclient -v -i port2 --no-pid
ip netns exec vm2 ip a show port2

ovs-vsctl add-port br-int port3 -- \
  set interface port3 \
    type=internal \
    mac='["c0:ff:ee:00:00:13"]' \
    external_ids:iface-id=port3

ip netns add vm3
ip link set netns vm3 port3
ip -n vm3 addr add 127.0.0.1/8 dev lo
ip -n vm3 link set lo up
ip netns exec vm3 dhclient -v -i port3 --no-pid
ip netns exec vm3 ip a show port3


ip netns exec vm2 ping -c3 10.0.0.11
ip netns exec vm3 ping -c3 10.0.0.11
ip netns exec vm3 ping -c3 10.0.0.12

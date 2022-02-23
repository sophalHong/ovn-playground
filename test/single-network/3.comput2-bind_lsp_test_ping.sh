#!/bin/bash -e

[[ "$EUID" -ne 0 ]] && { echo "Please run as root!"; exit; }

ovs-vsctl add-port br-int vm2 -- set Interface vm2 type=internal -- set Interface vm2 external_ids:iface-id=vm2

ip netns add vm2
ip link set vm2 netns vm2
ip netns exec vm2 ip link set vm2 address 40:44:00:00:00:02
ip netns exec vm2 ip addr add 192.168.0.12/24 dev vm2
ip netns exec vm2 ip link set vm2 up
ip netns exec vm2 ip a

ip netns exec vm2 ping 192.168.0.11 -c3

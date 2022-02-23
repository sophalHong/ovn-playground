#!/bin/bash -e

[[ "$EUID" -ne 0 ]] && { echo "Please run as root!"; exit; }

ovs-vsctl add-port br-int vm1 -- set Interface vm1 type=internal -- set Interface vm1 external_ids:iface-id=vm1

ip netns add vm1
ip link set vm1 netns vm1
ip netns exec vm1 ip link set vm1 address 40:44:00:00:00:01
ip netns exec vm1 ip addr add 192.168.0.11/24 dev vm1
ip netns exec vm1 ip link set vm1 up
ip netns exec vm1 ip route add default via 192.168.0.1
ip netns exec vm1 ip a

# ip netns exec vm1 ping 192.168.1.11 -c3

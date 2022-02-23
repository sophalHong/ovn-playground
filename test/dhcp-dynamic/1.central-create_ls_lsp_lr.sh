#!/bin/bash -e

[[ "$EUID" -ne 0 ]] && { echo "Please run as root!"; exit; }

# Create a logical switch
ovn-nbctl ls-add net0  
# Set subnet to logical switch net0
ovn-nbctl set logical_switch net0 \
  other_config:subnet="10.0.0.0/24" \
  other_config:exclude_ips="10.0.0.1..10.0.0.10"
ovn-nbctl --column name,other_config list logical_switch net0

# Create DHCP options
ovn-nbctl dhcp-options-create 10.0.0.0/24
CIDR_UUID=$(ovn-nbctl --bare --columns=_uuid find dhcp_options cidr="10.0.0.0/24")
ovn-nbctl dhcp-options-set-options ${CIDR_UUID} \
  lease_time=3600 \
  router=10.0.0.1 \
  server_id=10.0.0.1 \
  server_mac=c0:ff:ee:00:00:01
ovn-nbctl list dhcp_options

# Create Logical ports
# Port1
ovn-nbctl lsp-add net0 port1
ovn-nbctl lsp-set-addresses port1 "c0:ff:ee:00:00:11 dynamic"
ovn-nbctl lsp-set-dhcpv4-options port1 $CIDR_UUID
# Port2
ovn-nbctl lsp-add net0 port2
ovn-nbctl lsp-set-addresses port2 "c0:ff:ee:00:00:12 dynamic"
ovn-nbctl lsp-set-dhcpv4-options port2 $CIDR_UUID
# Port3
ovn-nbctl lsp-add net0 port3
ovn-nbctl lsp-set-addresses port3 "c0:ff:ee:00:00:13 dynamic"
ovn-nbctl lsp-set-dhcpv4-options port3 $CIDR_UUID

ovn-nbctl show

ovn-trace --summary net0 'inport=="port1" && eth.src==c0:ff:ee:00:00:11 && ip4.src==0.0.0.0 && ip.ttl==1 && ip4.dst==255.255.255.255 && udp.src==68 && udp.dst==67'

#!/bin/bash -e

[[ "$EUID" -ne 0 ]] && { echo "Please run as root!"; exit; }

# Create two logical switches
ovn-nbctl ls-add network1
ovn-nbctl ls-add network2
# Create logical switch port
ovn-nbctl lsp-add network1 vm1
ovn-nbctl lsp-add network2 vm2
# Set logical switch port address
ovn-nbctl lsp-set-addresses vm1 "40:44:00:00:00:01 192.168.0.11"
ovn-nbctl lsp-set-addresses vm2 "40:44:00:00:00:02 192.168.1.11"

# Create logical router
ovn-nbctl lr-add router1
# Create logical router port for switch-1
ovn-nbctl lrp-add router1 router1-net1 40:44:00:00:00:03 192.168.0.1/24
# Create logical switch port connecto to logical router for switch-1
ovn-nbctl lsp-add network1 net1-router1
ovn-nbctl lsp-set-addresses net1-router1 40:44:00:00:00:03
ovn-nbctl lsp-set-type net1-router1 router
ovn-nbctl lsp-set-options net1-router1 router-port=router1-net1
# Create logical router port for switch-2
ovn-nbctl lrp-add router1 router1-net2 40:44:00:00:00:04 192.168.1.1/24
# Create logical switch port connecto to logical router for switch-2
ovn-nbctl lsp-add network2 net2-router1
ovn-nbctl lsp-set-addresses net2-router1 40:44:00:00:00:04
ovn-nbctl lsp-set-type net2-router1 router
ovn-nbctl lsp-set-options net2-router1 router-port=router1-net2

ovn-nbctl show; ovn-sbctl show

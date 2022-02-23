#!/bin/bash -e

[[ "$EUID" -ne 0 ]] && { echo "Please run as root!"; exit; }

ovn-nbctl ls-add network1
ovn-nbctl lsp-add network1 vm1
ovn-nbctl lsp-add network1 vm2
ovn-nbctl lsp-set-addresses vm1 "40:44:00:00:00:01 192.168.0.11"
ovn-nbctl lsp-set-addresses vm2 "40:44:00:00:00:02 192.168.0.12"

ovn-nbctl show; ovn-sbctl show

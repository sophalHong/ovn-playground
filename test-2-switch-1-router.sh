#!/bin/bash

# Create the first logical switch and its two ports.
ovn-nbctl ls-add sw0

ovn-nbctl lsp-add sw0 sw0-port1
ovn-nbctl lsp-set-addresses sw0-port1 "00:00:00:00:00:01 10.0.0.51"
ovn-nbctl lsp-set-port-security sw0-port1 "00:00:00:00:00:01 10.0.0.51"

ovn-nbctl lsp-add sw0 sw0-port2
ovn-nbctl lsp-set-addresses sw0-port2 "00:00:00:00:00:02 10.0.0.52"
ovn-nbctl lsp-set-port-security sw0-port2 "00:00:00:00:00:02 10.0.0.52"

# Create the second logical switch and its two ports.
ovn-nbctl ls-add sw1

ovn-nbctl lsp-add sw1 sw1-port1
ovn-nbctl lsp-set-addresses sw1-port1 "00:00:00:00:00:03 192.168.1.51"
ovn-nbctl lsp-set-port-security sw1-port1 "00:00:00:00:00:03 192.168.1.51"

ovn-nbctl lsp-add sw1 sw1-port2
ovn-nbctl lsp-set-addresses sw1-port2 "00:00:00:00:00:04 192.168.1.52"
ovn-nbctl lsp-set-port-security sw1-port2 "00:00:00:00:00:04 192.168.1.52"

# Create a logical router between sw0 and sw1.
ovn-nbctl create Logical_Router name=lr0

ovn-nbctl lrp-add lr0 lrp0 00:00:00:00:ff:01 10.0.0.1/24
ovn-nbctl lsp-add sw0 sw0-lrp0 \
    -- set Logical_Switch_Port sw0-lrp0 type=router \
    options:router-port=lrp0 addresses='"00:00:00:00:ff:01"'

ovn-nbctl lrp-add lr0 lrp1 00:00:00:00:ff:02 192.168.1.1/24
ovn-nbctl lsp-add sw1 sw1-lrp1 \
    -- set Logical_Switch_Port sw1-lrp1 type=router \
    options:router-port=lrp1 addresses='"00:00:00:00:ff:02"'

# Trace
ovn-trace --minimal sw0 'inport == "sw0-port1" && eth.src == 00:00:00:00:00:01 && ip4.src == 10.0.0.51 && eth.dst == 00:00:00:00:ff:01 && ip4.dst == 192.168.1.52 && ip.ttl == 32'                                
ovn-trace --summary sw0 'inport == "sw0-port1" && eth.src == 00:00:00:00:00:01 && ip4.src == 10.0.0.51 && eth.dst == 00:00:00:00:ff:01 && ip4.dst == 192.168.1.52 && ip.ttl == 32'                                
ovn-trace --detailed sw0 'inport == "sw0-port1" && eth.src == 00:00:00:00:00:01 && ip4.src == 10.0.0.51 && eth.dst == 00:00:00:00:ff:01 && ip4.dst == 192.168.1.52 && ip.ttl == 32'                               
#ovn-trace --detailed 1db2e778-03b3-4cd0-965a-7ed9132b7c4a 'inport == "eb8c0275-01d6-4851-b397-84c26f384ef1" && eth.src == 56:6f:1b:f4:00:06 && ip4.src == 10.0.0.3 && eth.dst == 56:6f:1b:f4:00:07 && ip4.dst == 10.0.0.4 && ip.ttl == 32'
#ovn-trace --summary 1db2e778-03b3-4cd0-965a-7ed9132b7c4a 'inport == "eb8c0275-01d6-4851-b397-84c26f384ef1" && eth.src == 56:6f:1b:f4:00:06 && eth.dst == 56:6f:1b:f4:00:07'                                       
#ovn-trace --detailed $sw 'inport == '"\"$port\""' && eth.src == '"$src"' && eth.dst == '"$dst"''

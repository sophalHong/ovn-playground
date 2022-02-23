# OVN Trace

### Create Two logical switches and one logical router (On Central node)

* Create the first logical switch
```bash
ovn-nbctl ls-add sw0
```

* Create logical switch ports
```bash
ovn-nbctl lsp-add sw0 sw0-port1
ovn-nbctl lsp-set-addresses sw0-port1 "00:00:00:00:00:01 10.0.0.51"
ovn-nbctl lsp-set-port-security sw0-port1 "00:00:00:00:00:01 10.0.0.51"
```
```bash
ovn-nbctl lsp-add sw0 sw0-port2
ovn-nbctl lsp-set-addresses sw0-port2 "00:00:00:00:00:02 10.0.0.52"
ovn-nbctl lsp-set-port-security sw0-port2 "00:00:00:00:00:02 10.0.0.52"
```

* Create the second logical switch
```bash
ovn-nbctl ls-add sw1
```

* Create logical switch ports
```bash
ovn-nbctl lsp-add sw1 sw1-port1
ovn-nbctl lsp-set-addresses sw1-port1 "00:00:00:00:00:03 192.168.1.51"
ovn-nbctl lsp-set-port-security sw1-port1 "00:00:00:00:00:03 192.168.1.51"
```
```bash
ovn-nbctl lsp-add sw1 sw1-port2
ovn-nbctl lsp-set-addresses sw1-port2 "00:00:00:00:00:04 192.168.1.52"
ovn-nbctl lsp-set-port-security sw1-port2 "00:00:00:00:00:04 192.168.1.52"
```

* Create logical router
```bash
ovn-nbctl create Logical_Router name=lr0
```

* Create logical router port connect to logical switch port
```bash
ovn-nbctl lrp-add lr0 lrp0 00:00:00:00:ff:01 10.0.0.1/24
ovn-nbctl lsp-add sw0 sw0-lrp0 \
    -- set Logical_Switch_Port sw0-lrp0 type=router \
    options:router-port=lrp0 addresses='"00:00:00:00:ff:01"'
```
```bash
ovn-nbctl lrp-add lr0 lrp1 00:00:00:00:ff:02 192.168.1.1/24
ovn-nbctl lsp-add sw1 sw1-lrp1 \
    -- set Logical_Switch_Port sw1-lrp1 type=router \
    options:router-port=lrp1 addresses='"00:00:00:00:ff:02"'
```

### Trace
* Minimal view
```bash
ovn-trace --minimal sw0 'inport == "sw0-port1" && eth.src == 00:00:00:00:00:01 && ip4.src == 10.0.0.51 && eth.dst == 00:00:00:00:ff:01 && ip4.dst == 192.168.1.52 && ip.ttl == 32'
```
```bash
[root@central ~]# ovn-trace --minimal sw0 'inport == "sw0-port1" && eth.src == 00:00:00:00:00:01 && ip4.src == 10.0.0.51 && eth.dst == 00:00:00:00:ff:01 && ip4.dst == 192.168.1.52 && ip.ttl == 32'
# ip,reg14=0x1,vlan_tci=0x0000,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:ff:01,nw_src=10.0.0.51,nw_dst=192.168.1.52,nw_proto=0,nw_tos=0,nw_ecn=0,nw_ttl=32
ip.ttl--;
eth.src = 00:00:00:00:ff:02;
eth.dst = 00:00:00:00:00:04;
output("sw1-port2");
```

* Summary view
```bash
ovn-trace --summary sw0 'inport == "sw0-port1" && eth.src == 00:00:00:00:00:01 && ip4.src == 10.0.0.51 && eth.dst == 00:00:00:00:ff:01 && ip4.dst == 192.168.1.52 && ip.ttl == 32'
```
```bash
[root@central ~]# ovn-trace --summary sw0 'inport == "sw0-port1" && eth.src == 00:00:00:00:00:01 && ip4.src == 10.0.0.51 && eth.dst == 00:00:00:00:ff:01 && ip4.dst == 192.168.1.52 && ip.ttl == 32'
# ip,reg14=0x1,vlan_tci=0x0000,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:ff:01,nw_src=10.0.0.51,nw_dst=192.168.1.52,nw_proto=0,nw_tos=0,nw_ecn=0,nw_ttl=32
ingress(dp="sw0", inport="sw0-port1") {
    next;
    next;
    outport = "sw0-lrp0";
    output;
    egress(dp="sw0", inport="sw0-port1", outport="sw0-lrp0") {
        next;
        output;
        /* output to "sw0-lrp0", type "patch" */;
        ingress(dp="lr0", inport="lrp0") {
            xreg0[0..47] = 00:00:00:00:ff:01;
            next;
            reg9[2] = 1;
            next;
            next;
            reg7 = 0;
            next;
            ip.ttl--;
            reg8[0..15] = 0;
            reg0 = ip4.dst;
            reg1 = 192.168.1.1;
            eth.src = 00:00:00:00:ff:02;
            outport = "lrp1";
            flags.loopback = 1;
            next;
            next;
            reg8[0..15] = 0;
            next;
            next;
            eth.dst = 00:00:00:00:00:04;
            next;
            output;
            egress(dp="lr0", inport="lrp0", outport="lrp1") {
                reg9[4] = 0;
                next;
                output;
                /* output to "lrp1", type "patch" */;
                ingress(dp="sw1", inport="sw1-lrp1") {
                    next;
                    next;
                    outport = "sw1-port2";
                    output;
                    egress(dp="sw1", inport="sw1-lrp1", outport="sw1-port2") {
                        next;
                        output;
                        /* output to "sw1-port2", type "" */;
                    };
                };
            };
        };
    };
};
```

* Detailed view
```bash
ovn-trace --detailed sw0 'inport == "sw0-port1" && eth.src == 00:00:00:00:00:01 && ip4.src == 10.0.0.51 && eth.dst == 00:00:00:00:ff:01 && ip4.dst == 192.168.1.52 && ip.ttl == 32'
```
```bash
[root@central ~]# ovn-trace --detailed sw0 'inport == "sw0-port1" && eth.src == 00:00:00:00:00:01 && ip4.src == 10.0.0.51 && eth.dst == 00:00:00:00:ff:01 && ip4.dst == 192.168.1.52 && ip.ttl == 32'       [23/23]
# ip,reg14=0x1,vlan_tci=0x0000,dl_src=00:00:00:00:00:01,dl_dst=00:00:00:00:ff:01,nw_src=10.0.0.51,nw_dst=192.168.1.52,nw_proto=0,nw_tos=0,nw_ecn=0,nw_ttl=32
                                                    
ingress(dp="sw0", inport="sw0-port1")                                                                    
-------------------------------------
 0. ls_in_port_sec_l2 (northd.c:5493): inport == "sw0-port1" && eth.src == {00:00:00:00:00:01}, priority 50, uuid 99a95669
    next;                                                                                                
 1. ls_in_port_sec_ip (northd.c:5126): inport == "sw0-port1" && eth.src == 00:00:00:00:00:01 && ip4.src == {10.0.0.51}, priority 90, uuid 230dbd15
    next;                                                                                                
22. ls_in_l2_lkup (northd.c:8208): eth.dst == 00:00:00:00:ff:01, priority 50, uuid 6df40956
    outport = "sw0-lrp0";
    output;                                                                                              
                                                    
egress(dp="sw0", inport="sw0-port1", outport="sw0-lrp0")
--------------------------------------------------------
 0. ls_out_pre_lb (northd.c:5643): ip && outport == "sw0-lrp0", priority 110, uuid 548a64f7
    next;                       
 9. ls_out_port_sec_l2 (northd.c:5591): outport == "sw0-lrp0", priority 50, uuid 33bac353
    output;            
    /* output to "sw0-lrp0", type "patch" */
                                                                                                         
ingress(dp="lr0", inport="lrp0")
--------------------------------                                                                         
 0. lr_in_admission (northd.c:10509): eth.dst == 00:00:00:00:ff:01 && inport == "lrp0", priority 50, uuid 8acb3fff
    xreg0[0..47] = 00:00:00:00:ff:01;
    next;                                                                                                
 1. lr_in_lookup_neighbor (northd.c:10652): 1, priority 0, uuid 1b67611e
    reg9[2] = 1;                                                                                                                                                                                                   
    next;                       
 2. lr_in_learn_neighbor (northd.c:10661): reg9[2] == 1, priority 100, uuid c7ab351b
    next;                                                                                                
10. lr_in_ip_routing_pre (northd.c:10895): 1, priority 0, uuid 1b60e4d3
    reg7 = 0;
    next;                                      
11. lr_in_ip_routing (northd.c:9425): ip4.dst == 192.168.1.0/24, priority 74, uuid 1887fea4
    ip.ttl--;                                                                                            
    reg8[0..15] = 0;
    reg0 = ip4.dst;
    reg1 = 192.168.1.1;                                                                                  
    eth.src = 00:00:00:00:ff:02;
    outport = "lrp1";                   
    flags.loopback = 1;
    next;                           
12. lr_in_ip_routing_ecmp (northd.c:10970): reg8[0..15] == 0, priority 150, uuid fdb5dc17
    next;                                                                                                
13. lr_in_policy (northd.c:11103): 1, priority 0, uuid 612d17bb
    reg8[0..15] = 0;                                                                                     
    next;
14. lr_in_policy_ecmp (northd.c:11105): reg8[0..15] == 0, priority 150, uuid 271908a2      
    next;                 
15. lr_in_arp_resolve (northd.c:11309): outport == "lrp1" && reg0 == 192.168.1.52, priority 100, uuid 8186381b
    eth.dst = 00:00:00:00:00:04;
    next;                                                                                                
19. lr_in_arp_request (northd.c:11785): 1, priority 0, uuid 6ddc0d67
    output;                                                                                                                                                                                                        
                                                    
egress(dp="lr0", inport="lrp0", outport="lrp1")
-----------------------------------------------                                                                                                                                                                    
 0. lr_out_chk_dnat_local (northd.c:13011): 1, priority 0, uuid a8a2d111
    reg9[4] = 0;                                                                                         
    next;
 6. lr_out_delivery (northd.c:11833): outport == "lrp1", priority 100, uuid 5d2309d9
    output;
    /* output to "lrp1", type "patch" */

ingress(dp="sw1", inport="sw1-lrp1")
------------------------------------
 0. ls_in_port_sec_l2 (northd.c:5493): inport == "sw1-lrp1", priority 50, uuid b36c0596
    next;
 6. ls_in_pre_lb (northd.c:5640): ip && inport == "sw1-lrp1", priority 110, uuid 5f4d8629
    next;
22. ls_in_l2_lkup (northd.c:8208): eth.dst == 00:00:00:00:00:04, priority 50, uuid 7180b56e
    outport = "sw1-port2";
    output;

egress(dp="sw1", inport="sw1-lrp1", outport="sw1-port2")
--------------------------------------------------------
 8. ls_out_port_sec_ip (northd.c:5126): outport == "sw1-port2" && eth.dst == 00:00:00:00:00:04 && ip4.dst == {255.255.255.255, 224.0.0.0/4, 192.168.1.52}, priority 90, uuid 19ebc92e
    next;
 9. ls_out_port_sec_l2 (northd.c:5591): outport == "sw1-port2" && eth.dst == {00:00:00:00:00:04}, priority 50, uuid be817674
    output;
    /* output to "sw1-port2", type "" */
```

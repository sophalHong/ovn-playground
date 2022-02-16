# Two networks with one Router
```
                               +--------------+
          |--------------------|   Router1    |--------------------|
          |     192.168.0.1    +--------------+    192.168.1.1     |
          |  40:44:00:00:00:03                  40:44:00:00:00:04  |
          |                                                        |
+--------------------+                                  +---------------------+
|      Network1      |                                  |       Network2      |
|   192.168.0.0/24   |                                  |    192.168.1.0/24   |
+--------------------+                                  +---------------------+                                                                          
          |                                                        |
          |                                                        |
+---------------------+                                 +---------------------+                                                                            
|        VM1          |                                 |         VM2         |
|    192.168.0.11     |                                 |    192.168.1.11     |
|  40:44:00:00:00:01  |                                 |  40:44:00:00:00:01  |
+---------------------+                                 +---------------------+
```

### Network setting on OVN Controller node
* Create two logical switches
```bash
ovn-nbctl ls-add network1
ovn-nbctl ls-add network2
```

* Create logical switch port
```bash
ovn-nbctl lsp-add network1 vm1
ovn-nbctl lsp-add network2 vm2
```

* Set logical switch port address
```bash
ovn-nbctl lsp-set-addresses vm1 "40:44:00:00:00:01 192.168.0.11"
ovn-nbctl lsp-set-addresses vm2 "40:44:00:00:00:02 192.168.1.11"
```

* Create logical router
```bash
ovn-nbctl lr-add router1
```

* Create logical router port for switch-1
```bash
ovn-nbctl lrp-add router1 router1-net1 40:44:00:00:00:03 192.168.0.1/24
```

* Create logical switch port connecto to logical router for switch-1
```bash
ovn-nbctl lsp-add network1 net1-router1
ovn-nbctl lsp-set-addresses net1-router1 40:44:00:00:00:03
ovn-nbctl lsp-set-type net1-router1 router
ovn-nbctl lsp-set-options net1-router1 router-port=router1-net1
```

* Create logical router port for switch-2
```bash
ovn-nbctl lrp-add router1 router1-net2 40:44:00:00:00:04 192.168.1.1/24
```

* Create logical switch port connecto to logical router for switch-2
```bash
ovn-nbctl lsp-add network2 net2-router1
ovn-nbctl lsp-set-addresses net2-router1 40:44:00:00:00:04
ovn-nbctl lsp-set-type net2-router1 router
ovn-nbctl lsp-set-options net2-router1 router-port=router1-net2
```

### Network setting on OVN Compute node-1
* Create port and set interface (fake VM1)
```bash
ovs-vsctl add-port br-int vm1 -- set Interface vm1 type=internal -- set Interface vm1 external_ids:iface-id=vm1
```
 * Create network namespace for VM1
 ```bash
 ip netns add vm1
 ip link set vm1 netns vm1
 ip netns exec vm1 ip link set vm1 address 40:44:00:00:00:01
 ip netns exec vm1 ip addr add 192.168.0.11/24 dev vm1
 ip netns exec vm1 ip link set vm1 up
 ip netns exec vm1 ip route add default via 192.168.0.1
 ip netns exec vm1 ip a
 ```

### Network setting on OVN Compute node-2
* Create port and set interface (fake VM1)
```bash
ovs-vsctl add-port br-int vm2 -- set Interface vm2 type=internal -- set Interface vm2 external_ids:iface-id=vm2
```

* Create network namespace for VM2
```bash
ip netns add vm2
ip link set vm2 netns vm2
ip netns exec vm2 ip link set vm2 address 40:44:00:00:00:02
ip netns exec vm2 ip addr add 192.168.1.11/24 dev vm2
ip netns exec vm2 ip link set vm2 up
ip netns exec vm2 ip route add default via 192.168.1.1
ip netns exec vm2 ip a
```

### Testing connection from VM1 to VM2 (OVN compute node-1)
* Executing ping command
```bash
[root@compute1 ~]# ip netns exec vm1 ping 192.168.1.11 -c3
PING 192.168.1.11 (192.168.1.11) 56(84) bytes of data.
64 bytes from 192.168.1.11: icmp_seq=1 ttl=63 time=2.75 ms
64 bytes from 192.168.1.11: icmp_seq=2 ttl=63 time=0.809 ms
64 bytes from 192.168.1.11: icmp_seq=3 ttl=63 time=0.949 ms

--- 192.168.1.11 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 0.809/1.503/2.751/0.884 ms

```

### Testing connection from VM2 to VM1 (OVN compute node-2)
* Executing ping command
```bash
[root@compute2 ~]# ip netns exec vm2 ping 192.168.0.11 -c3
PING 192.168.0.11 (192.168.0.11) 56(84) bytes of data.
64 bytes from 192.168.0.11: icmp_seq=1 ttl=63 time=1.37 ms
64 bytes from 192.168.0.11: icmp_seq=2 ttl=63 time=0.451 ms
64 bytes from 192.168.0.11: icmp_seq=3 ttl=63 time=0.739 ms

--- 192.168.0.11 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2048ms
rtt min/avg/max/mdev = 0.451/0.852/1.366/0.381 ms
```

## OVN-trace (on OVN Controller node)
Let's now check with ovn-trace how the flow of a packet from VM1 to VM2 looks like.
```bash
ovn-trace --summary network1 'inport == "vm1" && eth.src == 40:44:00:00:00:01 && eth.dst == 40:44:00:00:00:03 && ip4.src == 192.168.0.11 && ip4.dst == 192.168.1.11 && ip.ttl == 64'
```
```bash
[root@control ~]# ovn-trace --summary network1 'inport == "vm1" && eth.src == 40:44:00:00:00:01 && eth.dst == 40:44:00:00:00:03 && ip4.src == 192.168.0.11 && ip4.dst == 192.168.1.11 && ip.ttl == 64'
# ip,reg14=0x1,vlan_tci=0x0000,dl_src=40:44:00:00:00:01,dl_dst=40:44:00:00:00:03,nw_src=192.168.0.11,nw_dst=192.168.1.11,nw_proto=0,nw_tos=0,nw_ecn=0,nw_ttl=64
ingress(dp="network1", inport="vm1") {
    next;
    outport = "net1-router1";
    output;
    egress(dp="network1", inport="vm1", outport="net1-router1") {
        next;
        output;
        /* output to "net1-router1", type "patch" */;
        ingress(dp="router1", inport="router1-net1") {
            xreg0[0..47] = 40:44:00:00:00:03;
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
            eth.src = 40:44:00:00:00:04;
            outport = "router1-net2";
            flags.loopback = 1;
            next;
            next;
            reg8[0..15] = 0;
            next;
            next;
            eth.dst = 40:44:00:00:00:02;
            next;
            output;
            egress(dp="router1", inport="router1-net1", outport="router1-net2") {
                reg9[4] = 0;
                next;
                output;
                /* output to "router1-net2", type "patch" */;
                ingress(dp="network2", inport="net2-router1") {
                    next;
                    next;
                    outport = "vm2";
                    output;
                    egress(dp="network2", inport="net2-router1", outport="vm2") {
                        output;
                        /* output to "vm2", type "" */;
                    };
                };
            };
        };
    };
};

```

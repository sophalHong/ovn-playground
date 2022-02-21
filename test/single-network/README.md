# Single network - One Logical switch
```
                               +----------------+
                               |    Network1    |
          |--------------------| Logical Switch |--------------------|
          |                    | 192.168.0.0/24 |                    |
          |                    +----------------+                    |
          |                                                          |
          |                                                          |
+---------------------+                                 +---------------------+                                                                            
|        VM1          |                                 |         VM2         |
|    192.168.0.11     |                                 |    192.168.0.12     |
|  40:44:00:00:00:01  |                                 |  40:44:00:00:00:02  |
+---------------------+                                 +---------------------+
```

* Create Logical switch 'network1' and 2 ports (on OVN-controller node)
```bash
ovn-nbctl ls-add network1
ovn-nbctl lsp-add network1 vm1
ovn-nbctl lsp-add network1 vm2
ovn-nbctl lsp-set-addresses vm1 "40:44:00:00:00:01 192.168.0.11"
ovn-nbctl lsp-set-addresses vm2 "40:44:00:00:00:02 192.168.0.12"
```

* Check result 
```bash
[root@control ~]# ovn-nbctl show
switch 7efc2cce-8f80-4e70-8549-b59d6d390d28 (network1)
    port vm2
        addresses: ["40:44:00:00:00:02 192.168.0.12"]
    port vm1
        addresses: ["40:44:00:00:00:01 192.168.0.11"]
```
```bash
[root@control ~]# ovn-sbctl show
Chassis control.ovn.dev
    hostname: control.ovn.dev
    Encap geneve
        ip: "192.168.56.30"
        options: {csum="true"}
Chassis compute2.ovn.dev
    hostname: compute2.ovn.dev
    Encap geneve
        ip: "192.168.56.32"
        options: {csum="true"}    
Chassis compute1.ovn.dev
    hostname: compute1.ovn.dev
    Encap geneve
        ip: "192.168.56.31"
        options: {csum="true"}    
```

* Bind VM1 to Compute node 1
```bash
ovs-vsctl add-port br-int vm1 -- set Interface vm1 type=internal -- set Interface vm1 external_ids:iface-id=vm1

# Create network namespace for VM1
ip netns add vm1
ip link set vm1 netns vm1
ip netns exec vm1 ip link set vm1 address 40:44:00:00:00:01
ip netns exec vm1 ip addr add 192.168.0.11/24 dev vm1
ip netns exec vm1 ip link set vm1 up
ip netns exec vm1 ip a
```

* Bind VM2 to Compute node 2
```bash
ovs-vsctl add-port br-int vm2 -- set Interface vm2 type=internal -- set Interface vm2 external_ids:iface-id=vm2

# Create network namespace for VM2
ip netns add vm2
ip link set vm2 netns vm2
ip netns exec vm2 ip link set vm2 address 40:44:00:00:00:02
ip netns exec vm2 ip addr add 192.168.0.12/24 dev vm2
ip netns exec vm2 ip link set vm2 up
ip netns exec vm2 ip a
```

* Checking agian the Southbound database, we should see the port binding status
```bash
[root@control ~]# ovn-sbctl show
Chassis control.ovn.dev
    hostname: control.ovn.dev
    Encap geneve
        ip: "192.168.56.30"
        options: {csum="true"}
Chassis compute2.ovn.dev
    hostname: compute2.ovn.dev
    Encap geneve
        ip: "192.168.56.32"
        options: {csum="true"}
    Port_Binding vm2
Chassis compute1.ovn.dev
    hostname: compute1.ovn.dev
    Encap geneve
        ip: "192.168.56.31"
        options: {csum="true"}
    Port_Binding vm1
```

* Check connectivity between VM1 (compute1) and VM2 (compute2)
```bash
[root@compute1 ~]# ip netns exec vm1 ping 192.168.0.12 -c3
PING 192.168.0.12 (192.168.0.12) 56(84) bytes of data.
64 bytes from 192.168.0.12: icmp_seq=1 ttl=64 time=2.70 ms
64 bytes from 192.168.0.12: icmp_seq=2 ttl=64 time=1.26 ms
64 bytes from 192.168.0.12: icmp_seq=3 ttl=64 time=1.32 ms

--- 192.168.0.12 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 1.263/1.758/2.696/0.664 ms
```

```bash
[root@compute2 ~]# ip netns exec vm2 ping 192.168.0.11 -c3
PING 192.168.0.11 (192.168.0.11) 56(84) bytes of data.
64 bytes from 192.168.0.11: icmp_seq=1 ttl=64 time=2.72 ms
64 bytes from 192.168.0.11: icmp_seq=2 ttl=64 time=1.14 ms
64 bytes from 192.168.0.11: icmp_seq=3 ttl=64 time=1.21 ms

--- 192.168.0.11 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2005ms
rtt min/avg/max/mdev = 1.144/1.690/2.717/0.727 ms
```

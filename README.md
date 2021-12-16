# OVN-PlayGround
This repository is created for OVN playground, which OVN v21.12.90 is already installed on vagrant box.  
If you wish to get specific OVN version, please create your own one. [OVN-source](https://github.com/ovn-org/ovn)

### Bring up OVN environment
  ```bash
  vagrant up
  ```
  This will create 3 node - control, compute1, compute2  
  All is set! you are good to test...
  
### Verifying OVN cluster
- SSH connect to all node and change to root user
  ```bash
  vagrant ssh control # {compute1, compute2}
  sudo -i
  ```

- verifying settings
  ```bash
  ovs-vsctl list open_vswitch
  ovs-vsctl show
  ```
  
  ```bash
  [root@control ~]# ovs-vsctl show
  8637ba85-8d8a-4510-81cf-c56edf555c7c
    Bridge br-int
        fail_mode: secure
        datapath_type: system
        Port ovn-comput-0
            Interface ovn-comput-0
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.33.31"}
        Port br-int
            Interface br-int
                type: internal
        Port ovn-dd59c7-0
            Interface ovn-dd59c7-0
                type: geneve
                options: {csum="true", key=flow, remote_ip="192.168.33.32"}
    ovs_version: "2.16.90"
  ```
  
### Creating a Virtual network (on control node)
- Create a logical switch
  ```bash
  ovn-nbctl ls-add net0  
  ```
  ```bash
  [root@control ~]# ovn-nbctl show
  switch fa15873d-e015-452c-b60c-9259b3f47416 (net0)
  ```
  
- Set subnet to logical switch `net0`
  ```bash
  ovn-nbctl set logical_switch net0 \
    other_config:subnet="10.0.0.0/24" \
    other_config:exclude_ips="10.0.0.1..10.0.0.10"
  ```  
  ```bash
  [root@control ~]# ovn-nbctl --column name,other_config list logical_switch net0
  name                : net0
  other_config        : {exclude_ips="10.0.0.1..10.0.0.10", subnet="10.0.0.0/24"}  
  ```
  
- Create DHCP options
  ```bash
  ovn-nbctl dhcp-options-create 10.0.0.0/24
  CIDR_UUID=$(ovn-nbctl --bare --columns=_uuid find dhcp_options cidr="10.0.0.0/24")
  ovn-nbctl dhcp-options-set-options ${CIDR_UUID} \
    lease_time=3600 \
    router=10.0.0.1 \
    server_id=10.0.0.1 \
    server_mac=c0:ff:ee:00:00:01
  ```
  ```bash
  [root@control ~]# ovn-nbctl list dhcp_options
  _uuid               : 07b6bcda-e3b2-44b9-91c7-0eb3f66c6881
  cidr                : "10.0.0.0/24"
  external_ids        : {}
  options             : {lease_time="3600", router="10.0.0.1", server_id="10.0.0.1", server_mac="c0:ff:ee:00:00:01"}
  ```
  
- Create Logical ports
  ```bash  
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
  ```
  If you want OVN to set MAC address, `ovn-nbctl lsp-set-addresses port1 "dynamic"`  
  To set static IP, `ovn-nbctl lsp-set-addresses port1 "c0:ff:ee:00:00:11 10.0.0.11"`
  
  ```bash
  [root@control ~]# ovn-nbctl show
  switch fa15873d-e015-452c-b60c-9259b3f47416 (net0)
      port port3
          addresses: ["c0:ff:ee:00:00:13 dynamic"]
      port port1
          addresses: ["c0:ff:ee:00:00:11 dynamic"]
      port port2
          addresses: ["c0:ff:ee:00:00:12 dynamic"]
  ```
  Run `ovn-nbctl list logical_switch_port` to view detail
  

### Simulating a DHCP request with ovn-trace
```bash
[root@control ~]# ovn-trace --summary net0 'inport=="port1" && eth.src==c0:ff:ee:00:00:11 && ip4.src==0.0.0.0 && ip.ttl==1 && ip4.dst==255.255.255.255 && udp.src==68 && udp.dst==67'
# udp,reg14=0x1,vlan_tci=0x0000,dl_src=c0:ff:ee:00:00:11,dl_dst=00:00:00:00:00:00,nw_src=0.0.0.0,nw_dst=255.255.255.255,nw_tos=0,nw_ecn=0,nw_ttl=1,tp_src=68,tp_dst=67
ingress(dp="net0", inport="port1") {
    next;
    reg0[3] = put_dhcp_opts(offerip = 10.0.0.11, lease_time = 3600, netmask = 255.255.255.0, router = 10.0.0.1, server_id = 10.0.0.1);
    /* We assume that this packet is DHCPDISCOVER or DHCPREQUEST. */;
    next;
    eth.dst = eth.src;
    eth.src = c0:ff:ee:00:00:01;
    ip4.src = 10.0.0.1;
    udp.src = 67;
    udp.dst = 68;
    outport = inport;
    flags.loopback = 1;
    output;
    egress(dp="net0", inport="port1", outport="port1") {
        output;
        /* output to "port1", type "" */;
    };
};
```
### Create an OVS port
- On compute1 host, create port1 with MAC `c0:ff:ee:00:00:11` we configured earlier
  ```bash
  ovs-vsctl add-port br-int port1 -- \
    set interface port1 \
      type=internal \
      mac='["c0:ff:ee:00:00:11"]' \
      external_ids:iface-id=port1
  ```
  check the result with `ovs-vsctl show`, find `Port "port1"`
    
  On control host, OVN should also be aware of this port.  
  Run `ovn-sbctl show` find `Port_Binding port1`

### Configure the port using DHCP
- on compute1 host, Create a namespace name `vm1` and make `port1` part of that namespace
  ```bash
  ip netns add vm1
  ip link set netns vm1 port1
  ip -n vm1 addr add 127.0.0.1/8 dev lo
  ip -n vm1 link set lo up
  ```
  
- configure the interface using DHCP by running `dhclient` command
  ```bash
  [root@compute1 ~]# ip netns exec vm1 dhclient -v -i port1 --no-pid
  Internet Systems Consortium DHCP Client 4.3.6
  
  Listening on LPF/port1/c0:ff:ee:00:00:11
  Sending on   LPF/port1/c0:ff:ee:00:00:11
  Sending on   Socket/fallback
  Created duid "\000\004\004 ]yC\222G\253\200\303\315\376.H\205\223".
  DHCPDISCOVER on port1 to 255.255.255.255 port 67 interval 7 (xid=0x98dfa90c)
  DHCPREQUEST on port1 to 255.255.255.255 port 67 (xid=0x98dfa90c)
  DHCPOFFER from 10.0.0.1
  DHCPACK from 10.0.0.1 (xid=0x98dfa90c)
  bound to 10.0.0.11 -- renewal in 1673 seconds.
  ```
  ```bash
  [root@compute1 ~]# ip netns exec vm1 ip a show port1
  7: port1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
      link/ether c0:ff:ee:00:00:11 brd ff:ff:ff:ff:ff:ff
      inet 10.0.0.11/24 brd 10.0.0.255 scope global dynamic port1
         valid_lft 3548sec preferred_lft 3548sec
      inet6 fe80::c2ff:eeff:fe00:11/64 scope link 
         valid_lft forever preferred_lft forever
  ```

### Configure OVS port2, port3
- On **compute1** host, create port2 with MAC `c0:ff:ee:00:00:12`
  ```bash
  ovs-vsctl add-port br-int port2 -- \
    set interface port2 \
      type=internal \
      mac='["c0:ff:ee:00:00:12"]' \
      external_ids:iface-id=port2
  ```

- create namespace `vm2` and configure dhcp for `port2`
  ```bash
  ip netns add vm2
  ip link set netns vm2 port2
  ip -n vm2 addr add 127.0.0.1/8 dev lo
  ip -n vm2 link set lo up  
  ip netns exec vm2 dhclient -v -i port2 --no-pid
  ```
  
- On **compute2** host, create port3 with MAC `c0:ff:ee:00:00:13`
  ```bash
  ovs-vsctl add-port br-int port3 -- \
    set interface port3 \
      type=internal \
      mac='["c0:ff:ee:00:00:13"]' \
      external_ids:iface-id=port3
  ```
  
- create namespace `vm3` and configure dhcp for `port3`
  ```bash
  ip netns add vm3
  ip link set netns vm3 port3
  ip -n vm3 addr add 127.0.0.1/8 dev lo
  ip -n vm3 link set lo up
  ip netns exec vm3 dhclient -v -i port3 --no-pid
  ```
  
- Verifying which port are binded to which host
  ```bash
  [root@control ~]# ovn-sbctl show
  Chassis compute2.ovn.dev
      hostname: compute2.ovn.dev
      Encap geneve
          ip: "192.168.33.32"
          options: {csum="true"}
      Port_Binding port3
  Chassis control.ovn.dev
      hostname: control.ovn.dev
      Encap geneve
          ip: "192.168.33.30"
          options: {csum="true"}
  Chassis compute1.ovn.dev
      hostname: compute1.ovn.dev
      Encap geneve
          ip: "192.168.33.31"
          options: {csum="true"}
      Port_Binding port1
      Port_Binding port2
  ```
  
### Verifying connectivity
- Check connection from vm1 to vm2 (the same chassis host) - compute1 host
  ```bash
  ip netns exec vm1 ping -c2 10.0.0.12
  ip netns exec vm2 ping -c2 10.0.0.11
  ```
  ```bash
  [root@compute1 ~]# ip netns exec vm2 ping -c2 10.0.0.11
  PING 10.0.0.11 (10.0.0.11) 56(84) bytes of data.
  64 bytes from 10.0.0.11: icmp_seq=1 ttl=64 time=0.058 ms
  64 bytes from 10.0.0.11: icmp_seq=2 ttl=64 time=0.047 ms

  --- 10.0.0.11 ping statistics ---
  2 packets transmitted, 2 received, 0% packet loss, time 1045ms
  rtt min/avg/max/mdev = 0.047/0.052/0.058/0.009 ms

  ```
  
- Check connection from vm3 to vm1/vm2 (different chassis host)
  ```bash
  ip netns exec vm3 ping -c2 10.0.0.11
  ip netns exec vm3 ping -c2 10.0.0.12
  ```
  ```bash
  [root@compute2 ~]# ip netns exec vm3 ping -c2 10.0.0.12
  PING 10.0.0.12 (10.0.0.12) 56(84) bytes of data.
  64 bytes from 10.0.0.12: icmp_seq=1 ttl=64 time=0.874 ms
  64 bytes from 10.0.0.12: icmp_seq=2 ttl=64 time=1.04 ms

  --- 10.0.0.12 ping statistics ---
  2 packets transmitted, 2 received, 0% packet loss, time 1007ms
  rtt min/avg/max/mdev = 0.874/0.957/1.041/0.089 ms
  ```
  
### References
- https://blog.oddbit.com/post/2019-12-19-ovn-and-dhcp/
- https://developers.redhat.com/blog/2018/09/03/ovn-dynamic-ip-address-management#
- https://developers.redhat.com/blog/2018/09/27/dynamic-ip-address-management-in-open-virtual-network-ovn-part-two
- http://dani.foroselectronica.es/simple-ovn-setup-in-5-minutes-491/
- http://dani.foroselectronica.es/ovn-routing-and-ovn-trace-550/
- https://blog.russellbryant.net/2016/11/11/ovn-logical-flows-and-ovn-trace/
- https://www.openvswitch.org/support/dist-docs-2.5/tutorial/OVN-Tutorial.md.html
- https://adhioutlined.github.io/virtual/Openvswitch-Cheat-Sheet/
  

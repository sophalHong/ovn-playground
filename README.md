# OVN-PlayGround
This repository is created for OVN playground, which OVN v21.12.90 is already installed on vagrant box.  
If you wish to get specific OVN version, please create your own one. [OVN-source](https://github.com/ovn-org/ovn)
```
                                         CMS
                                          |
                                          |
                              +-----------|-----------+
                              |           |           |
                              |     OVN/CMS Plugin    |
                              |           |           |
                              |           |           |
                              |   OVN Northbound DB   |
                              |           |           |
                              |           |           |
                              |       ovn-northd      |
                              |           |           |
                              +-----------|-----------+
                                          |
                                          |
                                +-------------------+
                                | OVN Southbound DB |
                                +-------------------+
                                          |
                                          |
                       +------------------+------------------+
                       |                  |                  |
         HV 1          |                  |    HV n          |
       +---------------|---------------+  .  +---------------|---------------+
       |               |               |  .  |               |               |
       |        ovn-controller         |  .  |        ovn-controller         |
       |         |          |          |  .  |         |          |          |
       |         |          |          |     |         |          |          |
       |  ovs-vswitchd   ovsdb-server  |     |  ovs-vswitchd   ovsdb-server  |
       |                               |     |                               |
       +-------------------------------+     +-------------------------------+

```

### Bring up OVN environment
```bash
vagrant up
```
This will create 3 node - central, compute1, compute2

```
                             +-------------------+
                             |      Central      |
    Southbound Database      |   ovn-controller  |        Southbound Database
             |-------------->|     ovn-northd    |<--------------|
             |               |   ovsdb-servers   |               |
             |               |   192.168.56.30   |               |
             |               +-------------------+               |
             |                     ||      ||                    |
             |                     ||      ||                    |
  +--------------------+           ||      ||          +--------------------+
  |      Compute1      |==========//        \\=========|      Compute2      |
  |   ovn-controller   |===============================|   ovn-controller   |
  |   192.168.56.31    |         Geneve tunnels        |   192.168.56.32    |
  +--------------------+                               +--------------------+
```
All is set! you are good to test...  

### Verifying OVN cluster
- SSH connect to all node and change to root user
  ```bash
  vagrant ssh central # {compute1, compute2}
  sudo -i
  ```

- verifying settings
  ```bash
  ovs-vsctl list open_vswitch
  ovs-vsctl show
  ```
  
  ```bash
  [root@central ~]# ovs-vsctl show
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
  
### Testing
* [A single network - One logical switch](test/single-network)
* [Multiple network - Two logical switches with one logical router](test/multiple-network)
* [DHCP - Assign dynamic ip address](test/dhcp-dynamic)
  
### References
- https://blog.oddbit.com/post/2019-12-19-ovn-and-dhcp/
- https://developers.redhat.com/blog/2018/09/03/ovn-dynamic-ip-address-management#
- https://developers.redhat.com/blog/2018/09/27/dynamic-ip-address-management-in-open-virtual-network-ovn-part-two
- http://dani.foroselectronica.es/simple-ovn-setup-in-5-minutes-491/
- http://dani.foroselectronica.es/ovn-routing-and-ovn-trace-550/
- https://blog.russellbryant.net/2016/11/11/ovn-logical-flows-and-ovn-trace/
- https://www.openvswitch.org/support/dist-docs-2.5/tutorial/OVN-Tutorial.md.html
- https://adhioutlined.github.io/virtual/Openvswitch-Cheat-Sheet/
  

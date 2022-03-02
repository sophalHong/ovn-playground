# OVN Gateway
```
                             +-------------------+
                             |  Physical Network |
                             +-------------------+
                                       |
                                       |
                                       |
                               +--------------+
                               |    Switch    | (Outside)
                               +--------------+
                                       |
                                       |
                                       |
                               +--------------+
          |--------------------|   Router1    |--------------------|
          |       10.0.0.1     +--------------+      20.0.0.1      |
          |  00:00:00:00:ff:01                  00:00:00:00:ff:02  |
          |                                                        |
+--------------------+                                  +---------------------+
|      Switch 0      |                                  |       Switch 1      |
|     10.0.0.0/24    |                                  |     20.0.0.0/24     |
+--------------------+                                  +---------------------+
          |                                                        |
          |                                                        |
+---------------------+                                 +---------------------+
|        VM1          |                                 |         VM2         |
|      10.0.0.3       |                                 |       20.0.0.3      |
|  00:00:01:00:00:03  |                                 |  00:00:02:00:00:03  |
+---------------------+                                 +---------------------+
```

* Configure `ovn-bridge-mappings`, map a physical network name to a local OVS bridge that provides connectivity to that network.
```bash
ovs-vsctl set open . external-ids:ovn-bridge-mappings=provider:br-provider
```

* Create the provider OVS bridge and add to the OVS bridge the interface that provides external connectivity:
```bash
ovs-vsctl --may-exist add-br br-provider
ovs-vsctl --may-exist add-port br-provider INTERFACE_NAME
```

* Create a couple of logical switches and logical ports and attach them to a logical router
```bash
ovn-nbctl ls-add sw0
ovn-nbctl lsp-add sw0 sw0-port1
ovn-nbctl lsp-set-addresses sw0-port1 "00:00:01:00:00:03 10.0.0.3"

ovn-nbctl ls-add sw1
ovn-nbctl lsp-add sw1 sw1-port1
ovn-nbctl lsp-set-addresses sw1-port1 "00:00:02:00:00:03 20.0.0.3"

ovn-nbctl lr-add lr0
# Connect sw0 to lr0
ovn-nbctl lrp-add lr0 lr0-sw0 00:00:00:00:ff:01 10.0.0.1/24
ovn-nbctl lsp-add sw0 sw0-lr0
ovn-nbctl lsp-set-type sw0-lr0 router
ovn-nbctl lsp-set-addresses sw0-lr0 router
ovn-nbctl lsp-set-options sw0-lr0 router-port=lr0-sw0

# Connect sw1 to lr0
ovn-nbctl lrp-add lr0 lr0-sw1 00:00:00:00:ff:02 20.0.0.1/24
ovn-nbctl lsp-add sw1 sw1-lr0
ovn-nbctl lsp-set-type sw1-lr0 router
ovn-nbctl lsp-set-addresses sw1-lr0 router
ovn-nbctl lsp-set-options sw1-lr0 router-port=lr0-sw1
```

* Check ovn-nbctl
```bash
> ovn-nbctl show
switch 05cf23bc-2c87-4d6d-a76b-f432e562ed71 (sw0)
    port sw0-port1
        addresses: ["00:00:01:00:00:03 10.0.0.3"]
    port sw0-lr0
        type: router
        router-port: lr0-sw0
switch 0dfee7ef-13b3-4cd0-87a1-7935149f551e (sw1)
    port sw1-port1
        addresses: ["00:00:02:00:00:03 20.0.0.3"]
    port sw1-lr0
        type: router
        router-port: lr0-sw1
router c189f271-86d6-4f7f-891c-672cb3aa543e (lr0)
    port lr0-sw0
        mac: "00:00:00:00:ff:01"
        networks: ["10.0.0.1/24"]
    port lr0-sw1
        mac: "00:00:00:00:ff:02"
        networks: ["20.0.0.1/24"]
```

* Create a provider logical switch
```bash
ovn-nbctl ls-add public
# Create a localnet port
ovn-nbctl lsp-add public ln-public
ovn-nbctl lsp-set-type ln-public localnet
ovn-nbctl lsp-set-addresses ln-public unknown
ovn-nbctl lsp-set-options ln-public network_name=provider
```

* Create a distributed router port
```bash
ovn-nbctl lrp-add lr0 lr0-public 00:00:20:20:12:13 192.168.56.200/24
ovn-nbctl lsp-add public public-lr0
ovn-nbctl lsp-set-type public-lr0 router
ovn-nbctl lsp-set-addresses public-lr0 router
ovn-nbctl lsp-set-options public-lr0 router-port=lr0-public
```
> We still need to schedule the distributed gateway port lr0-public to a gateway chassis. 
> What does scheduling mean here? 
> It means the chassis that is selected to host the gateway router port provides the centralized external connectivity. 
> The north-south tenant traffic will be redirected to this chassis and it acts as a gateway. 
> This chassis applies all the NATting rules before sending out the traffic via the patch port to the provider bridge. 
> It also means that when someone pings 192.168.56.200 or sends ARP request for 192.168.56.200, 
> the gateway chassis hosting this will respond with the ping and ARP replies.

* Scheduling the gateway router port
  * Scheduling in non-HA mode
  ```bash
  ovn-nbctl set logical_router_port lr0-public options:redirect-chassis=central.ovn.dev
  ovn-nbctl list logical_router_port lr0-public
  ```
  
  * Scheduling in non-HA mode
  ```bash
  ovn-nbctl lrp-set-gateway-chassis lr0-public controller-0 20
  ovn-nbctl lrp-set-gateway-chassis lr0-public controller-1 15
  ovn-nbctl lrp-set-gateway-chassis lr0-public controller-2 10
  
  ovn-nbctl list gateway_chassis
  ovn-nbctl list logical_router_port lr0-public
  ovn-sbctl show
  ```

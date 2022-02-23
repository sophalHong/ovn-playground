# -*- mode: ruby -*-
# vi: set ft=ruby :
box = "itkh/ovn"
ovn_cfg = [
    {
     :name => "central",
     :host_name  => "central.ovn.dev",
     :ip => "192.168.56.30",
     :memory => 2048,
     :cpus => 2,
   },{
     :name => "compute1",
     :host_name  => "compute1.ovn.dev",
     :ip => "192.168.56.31",
     :memory => 2048,
     :cpus => 2,
   },{
     :name => "compute2",
     :host_name  => "compute2.ovn.dev",
     :ip => "192.168.56.32",
     :memory => 2048,
     :cpus => 2,
   },
]

Vagrant.configure("2") do |config|
  config.vm.box = box
  config.vm.box_check_update = false
  #config.ssh.insert_key = false

  ovn_cfg.each do |server|
    config.vm.define server[:name] do |node|
      node.vm.hostname = server[:host_name]
      node.vm.network :private_network, ip: server[:ip]

      config.vm.provider :virtualbox do |vb|
        vb.memory = server[:memory]
        vb.cpus = server[:cpus]
      end
	    
      node.vm.provision "shell", inline: "systemctl status openvswitch ovn-controller --no-pager"

      if server[:name] == "central"
        node.vm.provision "shell", inline: <<-SHELL
          systemctl enable --now ovn-northd
          systemctl status ovn-northd --no-pager
          ovn-sbctl set-connection ptcp:6642
        SHELL
      end

      node.vm.provision "shell", inline: <<-SHELL
        ovs-vsctl set open_vswitch . \
          external_ids:ovn-remote=tcp:#{ovn_cfg[0][:ip]}:6642 \
          external_ids:ovn-encap-ip=#{server[:ip]} \
          external_ids:ovn-encap-type=geneve \
          external_ids:system-id=$(hostname) \
          external_ids:hostname=$(hostname)
        
        echo "============================="
        echo "$ ovs-vsctl list open_vswitch"
        ovs-vsctl list open_vswitch
        echo
        echo "============================="
        echo "$ ovs-vsctl show"
        ovs-vsctl show
      SHELL
    end
  end
end

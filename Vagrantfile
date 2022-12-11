network="10.0.0."
loadbalancer_host=50
master_host=51
number_worker_nodes=2

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-20.04"
	
  config.vm.provision "shell", env: {"network" => network, "master_host" => master_host}, inline: <<-SHELL
      apt-get update -y
      echo "$network$((master_host)) cai-master" >> /etc/hosts
      echo "$network$((master_host+1)) cai-worker1" >> /etc/hosts
      echo "$network$((master_host+2)) cai-worker2" >> /etc/hosts
  SHELL

  config.vm.synced_folder "shared/", "/shared", create: true
  #config.vm.boot_timeout = 600

  config.vm.define "master" do |master|
    master.vm.hostname = "cai-master"
    master.vm.network "private_network", ip: network + "#{master_host}"
	master.vm.provision "shell", path: "k8s_setup.sh"
    master.vm.provider "virtualbox" do |vb|
        vb.memory = 4048
        vb.cpus = 2
    end
  end

  (1..number_worker_nodes).each do |i|

  config.vm.define "worker#{i}" do |worker|
    worker.vm.hostname = "cai-worker#{i}"
    worker.vm.network "private_network", ip: network + "#{master_host + i}"
	worker.vm.provision "shell", path: "k8s_setup.sh"
    worker.vm.provider "virtualbox" do |vb|
        vb.memory = 2048
        vb.cpus = 1
    end
  end  
  end
  config.vm.define "loadbalancer" do |loadbalancer|
    loadbalancer.vm.hostname = "cai-loadbalancer"
    loadbalancer.vm.network "private_network", ip: network + "#{loadbalancer_host}"
	loadbalancer.vm.provision "shell", path: "loadbalancer.sh"
    loadbalancer.vm.provider "virtualbox" do |vb|
        vb.memory = 1024
        vb.cpus = 2
    end
  end
  config.vm.provider "virtualbox" do |vb|
	vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
  end
end 

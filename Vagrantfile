# Kubernetes Multi-Node Cluster with Vagrant and libvirt
# Control Plane: 1 node
# Workers: 2 nodes

NUM_WORKER_NODES = 2
IP_BASE = "192.168.56."
CONTROL_PLANE_IP = "#{IP_BASE}10"

Vagrant.configure("2") do |config|
  # Use Ubuntu 22.04 LTS
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_check_update = false

  # Provision all nodes with common setup
  config.vm.provision "shell", path: "scripts/common.sh"

  # Control Plane Node
  config.vm.define "controlplane" do |cp|
    cp.vm.hostname = "controlplane"
    cp.vm.network "private_network", ip: CONTROL_PLANE_IP

    cp.vm.provider :libvirt do |v|
      v.memory = 2048
      v.cpus = 2
      v.driver = "kvm"
    end

    # Initialize control plane
    cp.vm.provision "shell", path: "scripts/controlplane.sh", args: CONTROL_PLANE_IP
  end

  # Worker Nodes
  (1..NUM_WORKER_NODES).each do |i|
    config.vm.define "worker#{i}" do |worker|
      worker.vm.hostname = "worker#{i}"
      worker.vm.network "private_network", ip: "#{IP_BASE}#{10+i}"

      worker.vm.provider :libvirt do |v|
        v.memory = 2048
        v.cpus = 2
        v.driver = "kvm"
      end

      # Join worker to cluster
      worker.vm.provision "shell", path: "scripts/worker.sh", args: CONTROL_PLANE_IP
    end
  end
end

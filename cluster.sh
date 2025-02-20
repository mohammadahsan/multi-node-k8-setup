#!/bin/bash

set -e

# Kubernetes Pod CIDR
POD_CIDR="10.10.0.0/16"

echo "🚀 Launching Kubernetes Nodes..."
multipass launch --name master -c 2 -m 2G -d 20G
multipass launch --name worker01 -c 2 -m 2G -d 20G
multipass launch --name worker02 -c 2 -m 2G -d 20G

# Get Master Node IP Dynamically
MASTER_IP=$(multipass list | grep master | awk '{print $3}' | head -n 1)
echo "✅ Master Node IP: $MASTER_IP"

# Function to Run Commands in a Multipass VM
run_in_vm() {
    VM_NAME=$1
    CMD=$2
    multipass exec $VM_NAME -- bash -c "$CMD"
}

# Install Dependencies on All Nodes
setup_node() {
    NODE_NAME=$1
    echo "🔧 Setting up $NODE_NAME..."

    run_in_vm $NODE_NAME "
        # Disable swap
        sudo swapoff -a
        sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

        # Load Kernel Modules
        cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
        sudo modprobe overlay
        sudo modprobe br_netfilter

        # Set System Parameters for Kubernetes Networking
        cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
        sudo sysctl --system

        # Install containerd
        curl -LO https://github.com/containerd/containerd/releases/download/v1.7.14/containerd-1.7.14-linux-amd64.tar.gz
        sudo tar Cxzvf /usr/local containerd-1.7.14-linux-amd64.tar.gz
        curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
        sudo mkdir -p /usr/local/lib/systemd/system/
        sudo mv containerd.service /usr/local/lib/systemd/system/
        sudo mkdir -p /etc/containerd
        containerd config default | sudo tee /etc/containerd/config.toml
        sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
        sudo systemctl daemon-reload
        sudo systemctl enable --now containerd

        # Install runc
        curl -LO https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
        sudo install -m 755 runc.amd64 /usr/local/sbin/runc

        # Install CNI Plugins
        curl -LO https://github.com/containernetworking/plugins/releases/download/v1.5.0/cni-plugins-linux-amd64-v1.5.0.tgz
        sudo mkdir -p /opt/cni/bin
        sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.5.0.tgz

        # Install kubeadm, kubelet, and kubectl
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl gpg

        curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
        echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

        sudo apt-get update
        sudo apt-get install -y kubelet=1.29.6-1.1 kubeadm=1.29.6-1.1 kubectl=1.29.6-1.1 --allow-downgrades --allow-change-held-packages
        sudo apt-mark hold kubelet kubeadm kubectl

        # Configure crictl
        sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock
    "
}

# Setup Master Node
setup_master() {
    echo "🚀 Initializing Kubernetes Control Plane on Master Node..."
    run_in_vm master "
        sudo kubeadm init --pod-network-cidr=$POD_CIDR --apiserver-advertise-address=$MASTER_IP --node-name master
    "

    # Fetch the Join Command
    JOIN_COMMAND=$(multipass exec master -- kubeadm token create --print-join-command)

    # Set Up kubectl on the Master Node
    run_in_vm master "
        mkdir -p \$HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config
        sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config
    "

    # Install Calico Network Plugin & Calico
    # curl -O https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/custom-resources.yaml
    run_in_vm master "
        kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/tigera-operator.yaml
        kubectl apply -f custom-resources.yaml
    "

    echo "✅ Master Node is set up successfully!"
}

# Setup Worker Nodes and Join Cluster
setup_worker() {
    NODE_NAME=$1
    echo "🔧 Setting up Worker Node: $NODE_NAME..."
    setup_node $NODE_NAME

    echo "🔗 Joining Worker Node: $NODE_NAME to Cluster..."
    run_in_vm $NODE_NAME "$JOIN_COMMAND"
}

# Execute Setup
setup_node master
setup_master
setup_worker worker01
setup_worker worker02

echo "🎉 Kubernetes Cluster is Set Up Successfully! Use 'kubectl get nodes' to verify."
# Kubernetes Cluster Setup with Multipass & Kubeadm

This repository contains a script to automate the setup of a **3-node Kubernetes cluster** using **Multipass** and **kubeadm**.

## 🚀 Setup Instructions

### 1️⃣ Clone the Repository
```bash
git clone https://github.com/your-github-username/k8s-multipass-cluster.git
cd k8s-multipass-cluster
```

2️⃣ Run the Setup Script
```
chmod +x setup-k8s-cluster.sh
./setup-k8s-cluster.sh
```

3️⃣ Verify the Cluster
After the script finishes, run:
```bash
multipass exec master -- kubectl get nodes
```

Expected Output:
```bash
NAME       STATUS   ROLES    AGE   VERSION
master     Ready    control-plane   5m    v1.29.6
worker01   Ready    <none>   3m    v1.29.6
worker02   Ready    <none>   3m    v1.29.6
```

📜 What This Script Does
	•	Launches 3 Multipass VMs (master, worker01, worker02).
	•	Configures networking and disables swap.
	•	Installs containerd, runc, and CNI plugins.
	•	Installs Kubernetes (kubeadm, kubectl, kubelet).
	•	Dynamically retrieves the Master Node IP from multipass list.
	•	Initializes Kubernetes on the master node.
	•	Joins the worker nodes to the cluster.
	•	Installs Calico as the network plugin.

🛠 Troubleshooting

If a node doesn’t join, try running:
```bash
multipass exec master -- kubeadm token create --print-join-command
```
Then manually run the command inside the worker node.

---

### **🚀 How to Use**
1. Save **`setup-k8s-cluster.sh`** and **`README.md`** in your repo.
2. **Run the script**:
```bash
chmod +x setup-k8s-cluster.sh
./setup-k8s-cluster.sh
```
3.	Check cluster status:
```bash
multipass exec master -- kubectl get nodes
```
# Kubernetes Cluster Setup Using Kubeadm on AWS EC2 Ubuntu Servers

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [AWS Setup](#aws-setup)
4. [Scripts Overview](#scripts-overview)
5. [Common Script](#common-script)
6. [Master Script](#master-script)
7. [Worker Script](#worker-script)
8. [Common Script Explanation](#common-script-explanation)
9. [Master Script Explanation](#master-script-explanation)
10. [Worker Script Explanation](#worker-script-explanation)
11. [Verification](#verification)
12. [Troubleshooting](#troubleshooting)
13. [Quick Reference](#quick-reference)

---

## 1. Architecture Overview
                +------------------+
                |   MASTER NODE    |
                |   (t2.medium)    |
                |   4GB RAM 2Core  |
                +--------+---------+
                         |
           +-------------+-------------+
           |                           |
+----------+-------+       +-----------+------+
|   WORKER NODE 1  |       |   WORKER NODE 2  |
|   (t2.micro)     |       |   (t2.micro)     |
|   1GB RAM 1Core  |       |   1GB RAM 1Core  |
+------------------+       +------------------+

### Types of Kubernetes Clusters

| Type | Tool | Node Failure Handling |
|------|------|-----------------------|
| Self Managed - Single Node | Minikube | Manual |
| Self Managed - Multi Node | Kubeadm | Manual |
| Cloud Managed - AWS | EKS | Automatic |
| Cloud Managed - Azure | AKS | Automatic |
| Cloud Managed - GCP | GKE | Automatic |

> **Note:** In self-managed clusters, if a POD fails Kubernetes handles
> it automatically. But if a NODE fails, you need to fix it manually.

---

## 2. Prerequisites

### EC2 Instance Requirements

| Node | Instance Type | RAM | CPU | Count |
|------|--------------|-----|-----|-------|
| Master | t2.medium | 4GB | 2 Core | 1 |
| Worker | t2.micro | 1GB | 1 Core | 2 |

### Software Requirements
- Ubuntu OS (latest)
- ContainerD (Container Runtime)
- Kubeadm (Cluster Bootstrap Tool)
- Kubelet (Node Agent)
- Kubectl (CLI Tool)

---

## 3. AWS Setup

### Step 1 - Launch EC2 Instances

Go to AWS Console → EC2 → Launch Instance
Choose Ubuntu Server (latest LTS)
Master  → t2.medium
Workers → t2.micro (launch 2 instances)
Key pair → Create or use existing


### Step 2 - Security Group Rules
For now open ALL traffic (for learning purposes)
In production open only required ports:
Master Node Ports:
6443        - Kubernetes API Server
2379-2380   - etcd server client API
10250       - Kubelet API
10259       - kube-scheduler
10257       - kube-controller-manager
Worker Node Ports:
10250       - Kubelet API
30000-32767 - NodePort Services

### Step 3 - Connect to Instances
```bash
# Connect to Master
ssh -i your-key.pem ubuntu@<MASTER_PUBLIC_IP>

# Connect to Worker 1
ssh -i your-key.pem ubuntu@<WORKER1_PUBLIC_IP>

# Connect to Worker 2
ssh -i your-key.pem ubuntu@<WORKER2_PUBLIC_IP>
```

---

## 4. Scripts Overview
3 Scripts Total:

common.sh → Run on ALL nodes (Master + Workers)
master.sh → Run ONLY on Master node
worker.sh → Run ONLY on Worker nodes

Execution Order:
Master  → common.sh → master.sh
Worker1 → common.sh → worker.sh
Worker2 → common.sh → worker.sh

---

## 5. Common Script
### (Run on ALL Nodes - Master & Workers)

```bash
#!/bin/bash
set -euo pipefail

echo "================================================"
echo "   Common Setup - Master & Worker"
echo "================================================"

echo ">>> Step 1: Disable swap"
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo ">>> Step 2: Kernel settings"
cat <<KERNEL | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
KERNEL

modprobe overlay
modprobe br_netfilter

cat <<SYSCTL | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
SYSCTL

sysctl --system

echo ">>> Step 3: Install containerd"
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y containerd.io
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' \
  /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

echo ">>> Step 4: Install kubeadm kubelet kubectl"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | \
  gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
  https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | \
  tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
systemctl daemon-reload
systemctl start kubelet
systemctl enable kubelet.service

echo ">>> Step 5: Install conntrack"
apt update
apt install -y conntrack
which conntrack
conntrack -V

echo "================================================"
echo "Common Setup Complete!"
echo "================================================"
```

### How to run common.sh:
```bash
# Save the script
cat > common.sh << 'SCRIPT'
# paste above script here
SCRIPT

# Give permission
chmod +x common.sh

# Run as root
sudo su -
./common.sh
```

---

## 6. Master Script
### (Run ONLY on Master Node)

```bash
#!/bin/bash
set -euo pipefail

echo "================================================"
echo "   Master Node Setup"
echo "================================================"

echo ">>> Step 1: Initialize Kubernetes Master"
kubeadm init

echo ">>> Step 2: Configure kubectl as ubuntu user"
sudo -u ubuntu bash << 'UBUNTU'
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
UBUNTU

echo ">>> Step 3: Verify nodes"
sudo -u ubuntu kubectl get nodes
sudo -u ubuntu kubectl get pods -o wide -n kube-system

echo ">>> Step 4: Install Network"
#weave network
#sudo -u ubuntu kubectl apply -f \
#  https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
#calico network
sudo -u ${USER_NAME} kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

echo ">>> Waiting 30 seconds for pods to start..."
sleep 30

sudo -u ubuntu kubectl get nodes
sudo -u ubuntu kubectl get pods --all-namespaces

echo "================================================"
echo ">>> WORKER NODE JOIN COMMAND:"
echo "================================================"
kubeadm token create --print-join-command
echo "================================================"
echo "Master Setup Complete!"
echo "Copy the join command above and run on workers!"
echo "================================================"
```

### How to run master.sh:
```bash
# Save the script
cat > master.sh << 'SCRIPT'
# paste above script here
SCRIPT

# Give permission
chmod +x master.sh

# Run as root
sudo su -
./master.sh
```

---

## 7. Worker Script
### (Run ONLY on Worker Nodes)

```bash
#!/bin/bash
set -euo pipefail

echo "================================================"
echo "   Worker Node Setup"
echo "================================================"

echo "Please paste the kubeadm join command from master:"
read JOIN_COMMAND

echo ">>> Joining cluster..."
eval $JOIN_COMMAND

echo "================================================"
echo "Worker Node joined successfully!"
echo "Verify on master with: kubectl get nodes"
echo "================================================"
```

### How to run worker.sh:
```bash
# Save the script
cat > worker.sh << 'SCRIPT'
# paste above script here
SCRIPT

# Give permission
chmod +x worker.sh

# Run as root
sudo su -
./worker.sh
# When prompted paste the join command from master
```

---

## 8. Common Script Explanation

### set -euo pipefail
-e         → Exit immediately if any command fails
-u         → Treat unset variables as errors
-o pipefail → Catch errors in pipes

### Step 1 - Disable Swap
```bash
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```
Why?

Kubernetes REQUIRES swap to be disabled
If swap is enabled kubelet will NOT start
swapoff -a    → disables swap immediately
sed command   → comments out swap in fstab
to persist after reboot


### Step 2 - Kernel Settings
```bash
overlay
br_netfilter
```
Why?

overlay      → Required for container filesystem layering
br_netfilter → Required for pod-to-pod communication
modprobe     → Loads kernel modules immediately


```bash
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
```
Why?

Enables iptables to see bridged traffic
Required for CNI (Container Network Interface)
Enables IP forwarding for pod networking
sysctl --system → applies settings immediately


### Step 3 - Install ContainerD
Why ContainerD?

Kubernetes needs a container runtime
ContainerD is lightweight and production ready
We use Docker repo because containerd.io
package is distributed through Docker repo
We are NOT installing full Docker


```bash
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g'
```
Why SystemdCgroup = true?

Required for Kubernetes to manage cgroups properly
Without this pods may crash randomly
Must be set before starting kubelet


### Step 4 - Install Kubeadm Kubelet Kubectl
Tool        Purpose

kubelet   → Node agent runs on ALL nodes
manages pods on each node
kubeadm   → Bootstrap tool for cluster setup
only used during setup
kubectl   → CLI to interact with cluster
used to manage workloads
apt-mark hold → Prevents accidental upgrades
which could break the cluster

### Step 5 - Install Conntrack
Why?

Required for Kubernetes networking
Tracks network connections for services
Without it kube-proxy will not work


---

## 9. Master Script Explanation

### Step 1 - kubeadm init
What it does:

Bootstraps the Kubernetes control plane
Sets up these components:

API Server      → Main entry point for kubectl
etcd            → Key-value store for cluster data
Scheduler       → Assigns pods to nodes
Controller Mgr  → Manages cluster state


Generates certificates and kubeconfig files
Prints the worker join command at the end

If error occurs try:
kubeadm init --cri-socket /run/containerd/containerd.sock

### Step 2 - Configure Kubectl
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
Why?

kubectl needs kubeconfig to connect to cluster
MUST be run as normal ubuntu user NOT root
admin.conf   → contains cluster credentials
chown        → sets correct file ownership


### Step 3 - Install Weave Net
Why Network Addon?

Kubernetes needs CNI network addon
Without it pods CANNOT communicate
CoreDNS pods will be stuck without it
Weave Net provides pod-to-pod networking

IMPORTANT: Install ONLY ONE network addon!
Options:

Weave Net (used here)
Calico
Flannel


### Step 4 - Get Join Command
```bash
kubeadm token create --print-join-command
```
Output looks like:
kubeadm join <MASTER_IP>:6443 
--token <TOKEN> 
--discovery-token-ca-cert-hash sha256:<HASH>

Copy this ENTIRE command
Run on ALL worker nodes
Token expires after 24 hours


---

## 10. Worker Script Explanation

```bash
kubeadm join <MASTER_IP>:6443 \
  --token <TOKEN> \
  --discovery-token-ca-cert-hash sha256:<HASH>
```
What it does:

Connects the worker node to master
Downloads cluster certificates
Registers node with API server
Starts kubelet to manage pods
Worker is now ready to run workloads


---

## 11. Verification

### Check All Nodes on Master
```bash
kubectl get nodes
```
Expected Output:
NAME        STATUS   ROLES           AGE   VERSION
master      Ready    control-plane   10m   v1.31.x
worker-1    Ready    <none>          5m    v1.31.x
worker-2    Ready    <none>          5m    v1.31.x

### Check System Pods
```bash
kubectl get pods --all-namespaces
```
Expected Output:
All pods should show Running status
CoreDNS pods should be Running after Weave Net install

### Deploy Test Application
```bash
# Deploy nginx
kubectl run nginx-demo --image=nginx --port=80

# Check pod
kubectl get pods

# Create test namespace
kubectl create ns test

# Check pods in namespace
kubectl get pods -n test
```

---

## 12. Troubleshooting

### Issue 1 - Node Not Ready
```bash
# Check kubelet status
systemctl status kubelet

# Check kubelet logs
journalctl -u kubelet -f

# Fix - restart kubelet
systemctl restart kubelet
```

### Issue 2 - kubeadm init fails
```bash
# Reset and try again
kubeadm reset

# Try with explicit container runtime
kubeadm init --cri-socket /run/containerd/containerd.sock
```

### Issue 3 - Pods stuck in Pending
```bash
# Check pod details
kubectl describe pod <pod-name>

# Check node resources
kubectl describe node <node-name>

# Check events
kubectl get events --sort-by=.metadata.creationTimestamp
```

### Issue 4 - Worker cannot join
```bash
# On master - create new token
kubeadm token create --print-join-command

# On worker - reset and rejoin
kubeadm reset
# paste new join command
```

### Issue 5 - ContainerD not running
```bash
systemctl status containerd
systemctl restart containerd
journalctl -u containerd -f
```

### Issue 6 - kubectl not working
```bash
# Check kubeconfig
ls -la $HOME/.kube/config

# Re-copy config
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

## 13. Quick Reference Commands

### Cluster Management
```bash
kubectl get nodes                          # List all nodes
kubectl get nodes -o wide                  # List nodes with details
kubectl describe node <node-name>          # Node details
kubectl cluster-info                       # Cluster info
```

### Pod Management
```bash
kubectl get pods                           # List pods
kubectl get pods --all-namespaces          # All pods
kubectl get pods -o wide                   # Pods with node info
kubectl describe pod <pod-name>            # Pod details
kubectl logs <pod-name>                    # Pod logs
kubectl logs -f <pod-name>                 # Follow pod logs
kubectl delete pod <pod-name>              # Delete pod
kubectl exec -it <pod-name> -- /bin/bash   # Enter pod
```

### Namespace Management
```bash
kubectl get namespaces                     # List namespaces
kubectl create ns <name>                   # Create namespace
kubectl get pods -n <namespace>            # Pods in namespace
kubectl delete ns <name>                   # Delete namespace
```

### Token Management
```bash
kubeadm token list                         # List tokens
kubeadm token create --print-join-command  # New join command
kubeadm token delete <token>               # Delete token
```

---

## Script Execution Summary
==============================================
MASTER NODE:

sudo su -
./common.sh     ← Common setup (Step 1-5)
./master.sh     ← Master setup
exit            ← Exit root user
Copy join command from output

==============================================
WORKER NODE 1:

sudo su -
./common.sh     ← Common setup (Step 1-5)
./worker.sh     ← Paste join command

==============================================
WORKER NODE 2:

sudo su -
./common.sh     ← Common setup (Step 1-5)
./worker.sh     ← Paste join command

#install for commend master node servers
#!/bin/bash

#step 1
echo "###########################################"
echo "##### MASTER NODE STARTED  ################"
echo "###########################################"

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root (use sudo)"
  exit 1
fi
#########################################################################
echo "Step 2 started 🔧 Disabling swap..."                                # step 2 Disabling swap...

# Disable swap immediately
swapoff -a

# Disable swap permanently
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo "🔍 Verifying swap status..."

# Verify swap is disabled
SWAP_STATUS=$(free -h | grep Swap | awk '{print $2}')

if [[ "$SWAP_STATUS" == "0B" || "$SWAP_STATUS" == "0" ]]; then
  echo "✅ Swap is successfully disabled"
else
  echo "❌ Swap is still enabled. Please check manually"
  free -h
  exit 1
fi
echo "🎉 Step 2 completed successfully"                                  #step 2 ended 
#########################################################################

echo "================ STEP 3: Kernel & CNI Settings ================"  #step 3 started Adding kernel modules...

echo "⚙️ Adding kernel modules..."

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Load modules immediately
modprobe overlay
modprobe br_netfilter


echo "⚙️ Applying sysctl settings..."

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply changes
sysctl --system

echo "🔍 Verifying kernel settings..."

IP_FORWARD=$(sysctl -n net.ipv4.ip_forward)

if [ "$IP_FORWARD" -eq 1 ]; then
  echo "✅ Kernel settings applied successfully"
else
  echo "❌ Kernel settings not applied correctly"
  exit 1
fi

echo "🎉 Step 2 & Step 3 completed successfully"
########################################################################step 3 ended
echo "================ STEP 4: Install containerd ================"

echo "📦 Installing dependencies..."                               #step 4 for 
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

echo "🔑 Adding Docker GPG key..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "📁 Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "📦 Installing containerd..."
apt-get update -y
apt-get install -y containerd.io

echo "⚙️ Configuring containerd..."
#mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

# Enable systemd cgroup
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

echo "🔄 Restarting containerd..."
systemctl restart containerd
systemctl enable containerd

echo "🔍 Verifying containerd status..."

if systemctl is-active --quiet containerd; then
  echo "✅ containerd is running successfully"
else
  echo "❌ containerd failed to start"
  systemctl status containerd
  exit 1
fi

echo "🎉 Step 2, 3 & 4 completed successfully"               #step 4 completed
###############################################################################

echo "================ STEP 5: Install kubeadm, kubelet, kubectl ================"

apt-get update
apt-get install -y apt-transport-https ca-certificates curl

# Kubernetes key
#mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Kubernetes repo
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" \
  | tee /etc/apt/sources.list.d/kubernetes.list

# Install packages
apt-get update
apt-get install -y kubelet kubeadm kubectl

# Hold versions
apt-mark hold kubelet kubeadm kubectl

# Enable kubelet
systemctl daemon-reload
systemctl start kubelet
systemctl enable kubelet

echo "🔧 Installing conntrack..."
apt-get update
apt-get install -y conntrack

echo "🔍 Verifying conntrack..."
if which conntrack >/dev/null 2>&1; then
  conntrack -V
  echo "✅ conntrack installed"
else
  echo "❌ conntrack installation failed"
  exit 1
fi

echo "🎉 Step 1 → Step 5 completed successfully"
echo "########################### 1 to 5 steps completed #################"

################################################################################

# Set default user
USER_NAME=ubuntu
USER_HOME=/home/${USER_NAME}

#echo "🔧 Installing conntrack..."
#apt-get update
#apt-get install -y conntrack

#echo "🔍 Verifying conntrack..."
#which conntrack
#conntrack -V


echo "🚀 Initializing Kubernetes Master..."
kubeadm init

# Optional (if needed)
# kubeadm init --cri-socket /run/containerd/containerd.sock


echo "================ Configure kubectl ================"

mkdir -p ${USER_HOME}/.kube
cp -i /etc/kubernetes/admin.conf ${USER_HOME}/.kube/config
chown ${USER_NAME}:${USER_NAME} ${USER_HOME}/.kube/config


echo "================ Verify Cluster ================"

sudo -u ${USER_NAME} kubectl get nodes
sudo -u ${USER_NAME} kubectl get pods -n kube-system


echo "================ Install Network Addon  ================"

#wavre net  
#sudo -u ${USER_NAME} kubectl apply -f https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml
sudo -u ${USER_NAME} kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml


sleep 20

sudo -u ${USER_NAME} kubectl get nodes
sudo -u ${USER_NAME} kubectl get pods --all-namespaces


echo "================ Generate Join Command ================"

JOIN_CMD=$(kubeadm token create --print-join-command)
echo "👉 Run below command on WORKER nodes:"
echo "${JOIN_CMD}"


echo "================ Add Worker Machines to Kubernetes Master ================"
echo "Copy the above kubeadm join command and execute it on Worker Nodes to join the cluster"


echo "================ kubectl Commands (Run only on Master) ================"

sudo -u ${USER_NAME} kubectl get nodes


echo "================ Deploy Sample Application ================"

sudo -u ${USER_NAME} kubectl run nginx-demo --image=nginx --port=80
sudo -u ${USER_NAME} kubectl create ns test

echo "🎉 Kubernetes Master setup completed successfully!"
echo "***************************************************"
echo "###########################################"
echo "##### MASTER NODE ENDED  ##################"
echo "###########################################"

 #!/usr/bin/bash 
 
KUBERNETES_VERSION=v1.31
CRIO_VERSION=v1.31
echo "Define Env Vars"
echo "KUBERNETES_VERSION=$KUBERNETES_VERSION"
echo "CRIO_VERSION=$CRIO_VERSION"
echo "Install dependencies"
apt-get update
apt-get install -y software-properties-common curl
echo "Add the CRI-O repository"
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/stable:/$CRIO_VERSION/deb/ /" | tee /etc/apt/sources.list.d/cri-o.list
echo "Add the Kubernetes repository"
curl -fsSL https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$KUBERNETES_VERSION/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
echo "Install packages"
apt-get update
apt-get install -y cri-o kubelet kubeadm kubectl
echo "Start CRI-O"
systemctl start crio.service
echo "Bootstrap cluster"
swapoff -a
modprobe br_netfilter
sysctl -w net.ipv4.ip_forward=1

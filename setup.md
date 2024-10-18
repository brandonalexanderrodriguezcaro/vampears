# Create a k8s cluster

1. Install multipass, follow this [documentation](https://multipass.run/docs/install-multipass)
1. Once you have multipass, run 2 vms (master and worker node).
```shell
multipass launch -n k8s-master -c 2 -m 4G -d 7G 22.04
multipass launch -n k8s-worker-1 -c 2 -m 4G -d 7G 22.04
```
3. Once the vms are running go into each vm and run the following commands
```shell
multipass shell [vm-name]
```
4. Once you are there, run configure the root password:
```shell
sudo passwd
[define a password... e.g. ubuntu]
su
[enter password]
```
5. Run the prepare-node script:
```shell
apt update && apt upgrade ; apt install curl
curl -o https://raw.githubusercontent.com/brandonalexanderrodriguezcaro/vampirs/refs/heads/main/prepare-node.sh prepare-node.sh
chmod +x prepare-node.sh 
./prepare-node.sh 
```
6. On the master machine, initialize the cluster:
```shell
kubeadm init
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
kubeadm token create --print-join-command
```
7. On the worker node, copy the output of the last command and execute it in the worker node to join the cluster:
```shell
kubeadm join <api-server-ip:port> --token <token-value> --discovery-token-ca-cert-hash sha256:<hash value>
```


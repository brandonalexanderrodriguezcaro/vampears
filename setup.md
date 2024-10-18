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
curl https://raw.githubusercontent.com/brandonalexanderrodriguezcaro/vampirs/refs/heads/main/prepare-node.sh > prepare-node.sh
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
# Test the cluster
1. Run the following commands from the master node:
```shell
kubectl get nodes
```
You should see something like this:
```shell
NAME           STATUS   ROLES           AGE     VERSION
k8s-master     Ready    control-plane   5m31s   v1.31.1
k8s-worker-1   Ready    <none>          4m14s   v1.31.1
```
2. Try to run a workload:
```shell
kubectl apply -f https://raw.githubusercontent.com/brandonalexanderrodriguezcaro/vampirs/refs/heads/main/busybox.yaml
kubectl get all -o wide
```
You should see something like this:
```shell
NAME                                                            READY   STATUS    RESTARTS   AGE   IP          NODE           NOMINATED NODE   READINESS GATES
pod/deployments-simple-deployment-deployment-79f65b855c-k4gt7   1/1     Running   0          22s   10.85.0.2   k8s-worker-1   <none>           <none>
pod/deployments-simple-deployment-deployment-79f65b855c-lcz52   1/1     Running   0          22s   10.85.0.3   k8s-worker-1   <none>           <none>

NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE     SELECTOR
service/kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   3m30s   <none>

NAME                                                       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES    SELECTOR
deployment.apps/deployments-simple-deployment-deployment   2/2     2            2           22s   busybox      busybox   app=deployments-simple-deployment-app

NAME                                                                  DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES    SELECTOR
replicaset.apps/deployments-simple-deployment-deployment-79f65b855c   2         2         2       22s   busybox      busybox   app=deployments-simple-deployment-app,pod-template-hash=79f65b855c
```
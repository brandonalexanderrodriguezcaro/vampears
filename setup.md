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

# Bootstrap the cluster
This section will populate the cluster with useful tools
## Install Calico
```shell
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/refs/tags/v3.28.2/manifests/calico.yaml
```
## Install Argocd
Install the resources:
```shell
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
Now modify the service:
```shell
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "ClusterIP"}}'
```
Get the password:
```shell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d ; echo ''
```
Expose the service like this:
```shell
kubectl expose service argocd-server --type=NodePort --target-port=8080 --name=argocd-ext -n argocd
```
Look for the worker node ip:
```shell
multipass list
```
Now look for the ports exposed:
```shell
kubectl get svc -n argocd
```
You should see something like this:
```shell
NAME                                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
argocd-applicationset-controller          ClusterIP   10.97.120.243    <none>        7000/TCP,8080/TCP            77m
argocd-dex-server                         ClusterIP   10.108.78.85     <none>        5556/TCP,5557/TCP,5558/TCP   77m
argocd-ext                                NodePort    10.111.166.212   <none>        80:30445/TCP,443:31948/TCP   5s
argocd-metrics                            ClusterIP   10.105.112.191   <none>        8082/TCP                     77m
argocd-notifications-controller-metrics   ClusterIP   10.102.68.8      <none>        9001/TCP                     77m
argocd-redis                              ClusterIP   10.107.210.156   <none>        6379/TCP                     77m
argocd-repo-server                        ClusterIP   10.108.127.15    <none>        8081/TCP,8084/TCP            77m
argocd-server                             ClusterIP   10.98.255.162    <none>        80/TCP,443/TCP               77m
argocd-server-metrics                     ClusterIP   10.103.226.163   <none>        8083/TCP                     77m
```
Notice that the service argocd-ext is exposing the ports 30445 and 31948, check the values in your cluster and use the one related to the 443 of the internal service (in this example the value is 31948). Now open the web browser and search: ***https://[worker node ip]:[port of the ext service]***

## Install Helm
```shell
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
```
Check helm:
```shell
helm --help
```
## Install Prometheus
```shell
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/prometheus
kubectl expose service prometheus-server --type=NodePort --target-port=9090 --name=prometheus-server-ext
```
## Install Grafana
```shell
helm repo add grafana https://grafana.github.io/helm-charts 
helm repo update
helm install grafana grafana/grafana
kubectl expose service grafana --type=NodePort --target-port=3000 --name=grafana-ext
```
Now look for the ports exposed:
```shell
kubectl get svc 
```
You should see something like this:
```shell
NAME                                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
grafana                               ClusterIP   10.109.77.25     <none>        80/TCP         69m
grafana-ext                           NodePort    10.105.216.226   <none>        80:30226/TCP   68m
kubernetes                            ClusterIP   10.96.0.1        <none>        443/TCP        100m
prometheus-alertmanager               ClusterIP   10.111.198.132   <none>        9093/TCP       73m
prometheus-alertmanager-headless      ClusterIP   None             <none>        9093/TCP       73m
prometheus-kube-state-metrics         ClusterIP   10.96.16.184     <none>        8080/TCP       73m
prometheus-prometheus-node-exporter   ClusterIP   10.111.109.207   <none>        9100/TCP       73m
prometheus-prometheus-pushgateway     ClusterIP   10.96.182.137    <none>        9091/TCP       73m
prometheus-server                     ClusterIP   10.105.233.118   <none>        80/TCP         73m
prometheus-server-ext                 NodePort    10.106.121.110   <none>        80:30506/TCP   72m
```
Notice that the service grafana-ext is exposing the ports 30226, check the values in your cluster. Now open the web browser and search: ***https://[worker node ip]:[port of the ext service]***

To retrieve the password of the admin user use the following command:
```shell
kubectl get secret --namespace default grafana -o jsonpath="{.data.admin-password}" | base64 -d ; echo ""
```

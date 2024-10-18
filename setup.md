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
4. Once you are there, run the set-up:
```shell
sudo passwd
[define a password... e.g. ubuntu]
su
[enter password]
apt update && apt upgrade ; apt install curl
curl -o 
```

# What each of the shell scripts do?

## k8s-install.sh
Automates the installation and setup of `containerd`, `kubectl`, `kubeadm` and `kubelet`. It is to be executed on every single node (including control node).

## k8s-cleanup.sh
Automates the reset and graceful removal of `K8s`, `kubeadm`, `kubelet`, `kubectl`, `docker` and `containerd`. Please note that this will nuke everything, so take a backup of your K8 configurations before execution.

## check-root.sh
A simple reusable script to check whether `sudo` was applied to a given script execution.

## auth-x.sh
Automates granting executable privilege to scripts: `check-root.sh`, `k8s-cleanup.sh` and `k8s-install.sh` all at once, provided you set executable privilege `chmod +x auth-x.sh` (to `auth-x.sh` itself) before execution.


***

## Once you have executed the install script on every single node (including control plane), execute the following commands on the control plane to begin setting up your cluster :-

## For initializing the control plane :

    sudo kubeadm init --control-plane-endpoint="controller.lab.net"

## Get the control plane ready for accepting worker nodes :

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

## Validate cluster status :

    kubectl cluster-info
    kubectl get nodes
    
Any errors might mean trouble, so try `k8s-install.sh` script a few more times for a working result. Keep `ChatGPT` or `Claude` at your disposal as debugging this will not
be an easy feat.

## Install a container network interface like Calico:
You can use a different CNI like `Flannel` or swap the version for `Calico` in the URL below with a more recent one if needed:

    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml
    kubectl get pods -n kube-system

## For re-printing the join command 
Execute the output of the following command with `sudo` privilege within each of the worker nodes to let them join your cluster:

    sudo kubeadm token create --print-join-command



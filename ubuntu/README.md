# Follow steps below post K8s installation on the control plane :-

## For initializing the control plane :

    sudo kubeadm init --control-plane-endpoint="controller.lab.net"

## Get the control plane ready for accepting worker nodes :

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

## Validate cluster status :

    kubectl cluster-info
    kubectl get nodes

## Install a container network interface like Calico :

    kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml
    kubectl get pods -n kube-system

## For re-printing the join command :

    sudo kubeadm token create --print-join-command



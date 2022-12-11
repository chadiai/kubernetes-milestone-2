#!/bin/bash

# kubelet requires swap off
sudo swapoff -a
# keep swap off after reboot
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# firewall ports
sudo ufw allow 6443
sudo ufw allow 10250

master_ip="10.0.0.51"
node=$(hostname -s)
cidr="192.168.0.0/16"
my_ip=`hostname -i | awk '{print $2}'`
k8s_version="1.25.4-00"


cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system


# Install containerd (the container runtime)
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet="$k8s_version" kubectl="$k8s_version" kubeadm="$k8s_version"
sudo apt-mark hold kubelet kubeadm kubectl # prevent auto-updates


# kubeadm on master only
if [ $my_ip = $master_ip ]
then
  sudo kubeadm init --apiserver-advertise-address=$master_ip  --apiserver-cert-extra-sans=$master_ip  --pod-network-cidr=$cidr --node-name $node
  mkdir -p "$HOME"/.kube
  sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
  sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config
  
  #networking
  kubectl apply -f https://docs.projectcalico.org/manifests/calico-typha.yaml
  
  # Install HELM
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  
  # Prometheus
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update
  helm install prometheus prometheus-community/kube-prometheus-stack --set prometheusOperator.admissionWebhooks.enabled=false
  
  #containers
  kubectl apply -f /shared/yaml/nginx.yaml
  kubectl apply -f /shared/yaml/mongodb.yaml
  kubectl apply -f /shared/yaml/fastapi.yaml
  kubectl apply -f /shared/yaml/prometheus_service.yaml
  
  kubeadm token create --print-join-command > /shared/token.sh
  
  
else
  sudo /shared/token.sh
fi


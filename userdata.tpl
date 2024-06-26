#!/bin/bash
#----- System prepare -----#
sudo yum update -y
sudo yum install -y git docker go vi jq
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo yum install bash-completion
sudo source /usr/share/bash-completion/bash_completion
#----- Docker\Docker-compose install -----#
wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user


#----- K8S tools install -----#
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes --disableplugin=priorities
sudo systemctl enable --now kubelet
#---------------------------------------------------------------------#

#----- Helm install -----#
curl -o helm-v3.10.3-linux-amd64.tar.gz https://get.helm.sh/helm-v3.10.3-linux-amd64.tar.gz
chmod 777 helm-v3.10.3-linux-amd64.tar.gz
tar -zxvf helm-v3.10.3-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/sbin/helm
ll /usr/local/bin/helm
#---------------------------------------------------------------------#

#----- K8S cluster install -----#
#----- K8S 3 separated nodes cluster install -----#
%{ if k8s_type== "k8s_full" }
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
sudo swapoff -a
sudo crictl config runtime-endpoint unix:///var/run/containerd/containerd.sock

sudo echo "source <(kubectl completion bash)" >> /root/.bashrc
sudo echo "alias k='kubectl'" >> /root/.bashrc
sudo echo "alias kn='kubectl config set-context --current  --namespace'" >> /root/.bashrc
sudo echo "alias kpo='kubectl get po'" >> /root/.bashrc
sudo echo "alias kde='kubectl get deploy'" >> /root/.bashrc
sudo echo "alias ked='kubectl edit'" >> /root/.bashrc
sudo echo "alias kno='kubectl get no'" >> /root/.bashrc
sudo source /root/.bashrc
sudo complete -o default -F __start_kubectl k
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
sudo chmod a+r /etc/bash_completion.d/kubectl

cat <<EOF | sudo tee /root/.vimrc
set tabstop=2 softtabstop=2 shiftwidth=2
set expandtab
set number ruler
set autoindent smartindent
syntax enable
filetype plugin indent on
EOF

%{ endif }

#----- Master node -----#
%{ if K8S_role == "Master" }
echo '#!/bin/bash' > /tmp/k8s_join.sh
sudo kubeadm init --pod-network-cidr=${k8s_network} | grep -A 1 "kubeadm join" >> /tmp/k8s_join.sh
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config
sudo aws s3 cp /tmp/k8s_join.sh s3://${bucket_name}/k8s_join.sh
sudo aws s3 cp /etc/kubernetes/admin.conf s3://${bucket_name}/config


kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system

sudo kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
sudo kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml
sudo kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml

// kubectl delete -A ValidatingWebhookConfiguration ingress-nginx-admission
// kubectl edit configmap -n kube-system kube-proxy
// kubectl patch svc frontend -p '{"spec":{"externalIPs":["192.168.0.194"]}}'
%{ endif }

#----- Worker node -----#
%{ if K8S_role == "Worker" }
sleep 90
sudo mkdir -p /root/.kube
sudo aws s3 cp s3://${bucket_name}/config /root/.kube/config
sudo chown root:root /root/.kube/config
sudo aws s3 cp s3://${bucket_name}/k8s_join.sh /tmp/k8s_join.sh
sudo chmod +x /tmp/k8s_join.sh
sudo ./tmp/k8s_join.sh
sleep 60
sudo kubectl label node $(cat /etc/hostname) node-role.kubernetes.io/worker=worker
%{ endif }
#---------------------------------------------------------------------#


#----- Minikube install -----#
%{ if k8s_type == "minikube" }
sudo hostnamectl set-hostname ${k8s_type}
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install -o root -g root -m 0755 minikube-linux-amd64 /usr/bin/minikube
sudo minikube start --nodes ${k8s_minikube_nodes_ammount} --force
sudo cp -r /root/.kube /home/ec2-user/
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube
sudo cp -r /root/.minikube /home/ec2-user/
sudo chown -R ec2-user:ec2-user /home/ec2-user/.minikube
sudo sed -i 's/root/\home\/ec2-user/g' /home/ec2-user/.kube/config
sudo kubectl label $(sudo kubectl get no --no-headers --output=NAME|grep minikube-m*) node-role.kubernetes.io/worker=worker
%{ endif }
#---------------------------------------------------------------------#


#----- K8S dind install -----#
%{ if k8s_type == "dind" }
sudo hostnamectl set-hostname ${k8s_type}
wget -O dind-cluster.sh https://github.com/kubernetes-retired/kubeadm-dind-cluster/releases/download/v0.3.0/dind-cluster-v1.15.sh
chmod +x dind-cluster.sh
sudo install -o root -g root -m 0755  dind-cluster.sh /usr/bin/dind_cluster
sudo ./dind-cluster.sh up
sudo cp -r /root/.kube /home/ec2-user/
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube
sudo kubectl label $(sudo kubectl get no --no-headers --output=NAME|grep kube-node*) node-role.kubernetes.io/worker=worker
%{ endif }
#---------------------------------------------------------------------#

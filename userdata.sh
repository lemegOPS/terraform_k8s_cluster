#!/bin/bash

#----- System prepare -----#
sudo yum update -y
sudo yum install -y git docker go vi

#----- Docker\Docker-compose install -----#
wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/bin/docker-compos
sudo chmod -v +x /usr/bin/docker-compose
sudo usermod -a -G docker ec2-user
sudo systemctl start docker
sudo systemctl enable docker


#----- K8s tools install -----#
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet

wget -O dind-cluster.sh https://github.com/kubernetes-sigs/kubeadm-dind-cluster/releases/download/v0.2.0/dind-cluster-v1.14.sh 
chmod +x dind-cluster.sh
sudo ./dind-cluster.sh up

:'
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/bin/minikube


minikube start -n 3 -p k8s-mini --force --disk-size 2000mb

cd /home/ec2-user
git clone https://github.com/collabnix/kubelabs
cd kubelabs
chmod a+x bootstrap.sh
sudo sh bootstrap.sh

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
'

#----- K8S play ground install -----#
#cd /home/ec2-user
#git clone https://github.com/play-with-docker/play-with-docker
#cd play-with-docker
#sudo modprobe xt_ipvs
#docker swarm init
#docker pull franela/dind
#go mod vendor
#docker-compose up -d

#cd /home/ec2-user
#git clone https://github.com/play-with-docker/play-with-kubernetes.github.io.git
#cd play-with-kubernetes.github.io
#docker-compose up -d

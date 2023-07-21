#!/bin/bash

#----- System prepare -----#
sudo yum update -y
sudo yum install -y git docker go vi

#----- Docker\Docker-compose install -----#
wget https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) 
sudo mv docker-compose-$(uname -s)-$(uname -m) /usr/bin/docker-compose
sudo chmod +x /usr/bin/docker-compose

sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user


#----- K8S tools install -----#
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -m 0777 kubectl /usr/bin/kubectl


#----- K8S cluster install -----#

#----- K8S 3 separated nodes cluster install -----#
%{ if k8s_type == "k8s_full" }
cd /home/ec2-user
git clone https://github.com/collabnix/kubelabs
cd kubelabs
chmod a+x bootstrap.sh
sudo sh bootstrap.sh | grep join > /home/ec2-user/kubernetes_info.txt
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
%{ endif }

#----- Minikube install -----#
%{ if k8s_type == "minikube" }
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install -o root -g root -m 0755 minikube-linux-amd64 /usr/bin/minikube
sudo minikube start --nodes ${node_ammount} --force
sudo cp -r /root/.kube /home/ec2-user/
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube
sudo cp -r /root/.minikube /home/ec2-user/
sudo chown -R ec2-user:ec2-user /home/ec2-user/.minikube
sudo sed -i 's/root/\home\/ec2-user/g' /home/ec2-user/.kube/config
sudo kubectl label $(sudo kubectl get no --no-headers --output=NAME|grep minikube-m*) node-role.kubernetes.io/worker=worker
%{ endif }

#----- K8S dind install -----#
%{ if k8s_type == "dind" }
wget -O dind-cluster.sh https://github.com/kubernetes-retired/kubeadm-dind-cluster/releases/download/v0.3.0/dind-cluster-v1.15.sh
chmod +x dind-cluster.sh
sudo install -o root -g root -m 0755  dind-cluster.sh /usr/bin/dind_cluster
sudo ./dind-cluster.sh up
sudo cp -r /root/.kube /home/ec2-user/
sudo chown -R ec2-user:ec2-user /home/ec2-user/.kube
sudo kubectl label $(sudo kubectl get no --no-headers --output=NAME|grep kube-node*) node-role.kubernetes.io/worker=worker
%{ endif }
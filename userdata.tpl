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
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

sudo yum install -y kubelet kubeadm kubectl
sudo systemctl enable kubelet
sudo systemctl start kubelet


#----- K8S cluster install -----#

#----- K8S 3 separated nodes cluster install -----#
#----- Master node -----#
%{ if K8S_role == "Master" }
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
sudo swapoff -a
echo '#!/bin/bash' > /tmp/k8s_join.sh
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 | grep -A 1 "kubeadm join" >> /tmp/k8s_join.sh
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown root:root /root/.kube/config
sudo aws s3 cp /tmp/k8s_join.sh s3://${bucket_name}/k8s_join.sh
sudo aws s3 cp /etc/kubernetes/admin.conf s3://${bucket_name}/config
sudo kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml
%{ endif }

#----- Worker node -----#
%{ if K8S_role == "Worker" }
sleep 120
cat <<EOF > /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system
sudo swapoff -a
sudo mkdir -p /root/.kube
curl http://169.254.169.254/latest/meta-data/iam/info
sudo aws s3 cp s3://${bucket_name}/config /root/.kube/config
sudo chown root:root /root/.kube/config
sudo aws s3 cp s3://${bucket_name}/k8s_join.sh /tmp/k8s_join.sh
sudo chmod +x /tmp/k8s_join.sh
sudo ./tmp/k8s_join.sh
sudo kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter.yaml
sleep 60
sudo kubectl label node $(cat /etc/hostname) node-role.kubernetes.io/worker=worker
%{ endif }

#----- Minikube install -----#
%{ if k8s_type == "minikube" }
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
# Terraform Kubernetes dind cluster
### Terraform script for installing Kubernetes dind playground cluster

---
## How it works?

These terraform script deploys one EC2 instance in AWS on which a multinodes kubernete cluster is installed from the repository https://github.com/kubernetes-sigs/kubeadm-dind-cluster


---
### Important!
After deploying terraform, it takes from 2 to 10 minutes to install the cluster.

Recommended ec2 instance should have 2 CPU and 2 RAM

The file sg.tf contains lines of code (given below). The block gets your external local ip and adds it to the aws_security_group block in the ingress - cidr_blocks.
Since this is a playground cluster, access to it from the Internet is closed. You can replace cidr_blocks with 0.0.0.0/0 or [var.cidr_block["external"]] then access will be for the entire internet.


---
### Terraform script structure:
```
.
├── README.md
├── main.tf - main file to run
├── modules - directory with modules
│   ├── aws-instance 
│   │   ├── instance.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── aws-private-key
│   │   ├── aws-private-key.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── aws-s3
│   │   ├── outputs.tf
│   │   ├── s3.tf
│   │   └── variables.tf
│   ├── aws-sg
│   │   ├── outputs.tf
│   │   ├── sg.tf
│   │   └── variables.tf
│   └── aws-vpc
│       ├── outputs.tf
│       └── vpc.tf
├── outputs.tf - outputs with server address, server port and bucket name for states
├── provider.tf - providers here
├── userdata.tpl - script with docker and server installation in a container
└── variables.tf - main variable file
```


---
**To run scripts you need:**
```bash
git clone git@github.com:lemegOPS/terraform_k8s_dind_cluster.git
cd terraform_k8s_dind_clusterterr   
terraform init
terraform apply
```


---
**After installing the server, the script will give output:**

**Example**:
```bash
 bucket_name = "learning-k8s-dind-tfstate-7xyire"
 local_external_ip = "80.90.121.253"
 server_info = {
   "Learning_K8S_dind_1" = [
     "######### Instance info #########",
     "ID: i-0bcd8005a3dd0d5e7",
     "Instance type: t2.medium",
     "AMI: ami-0ee3dd41c47751fe6",
     "SSH Key: Learning_K8S_dind_SSH-key",
     "---------------------------------------",
     "######### Network info #########",
     "External IP: 3.91.20.16",
     "External DNS: ec2-3-91-7-4.compute-1.amazonaws.com",
     "Internal IP: 172.31.94.118",
     "---------------------------------------",
     "######### Manegment info #########",
     "Project: Learning",
     "Environment: K8S",
   ]
 }
```


---
**After successful creation of the server, a private ssh key with the name of the pattern *Project_Size_Name*_SSH-key.pem will appear in the directory with scripts. To connect to the server, use the command:**
```bash
ssh -i you_generated_ssh_key.pem ec2-user@ip_from_output
```


---
**Everything is controlled from the variables.tf file in the root module.**
**Below is a description of the variables:**
|Variable Name|Variable Value|
|-------------|--------------|
|variable "profile"|Value from ~/.aws/config. [How_to_config](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html#getting-started-quickstart-new-command)|
|region| Choose the right region|
|tags|From tags, a long name of all tags, a bucket according to the pattern, is formed: *Project_Size_Name* in *local* *global_name* of main.tf file|
|instance_type|Depending on what is specified in *tags* *Size*, the instance type is selected|
|ami_image|Filters can be anything. [Filter examples](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami)|
|sec_group|Ports, internals and networking of the server. *port_udp* is forwarded in userdata.tpl to container ports.|


---
After installation, you can start working with the cluster with the standard kubectl tool.
```bash
[root@ip-172-31-94-118 ~]# docker ps
CONTAINER ID   IMAGE                                                                          COMMAND                  CREATED         STATUS         PORTS                       NAMES
4a189e3e09a7   mirantis/kubeadm-dind-cluster:814d9ca036b23adce9e6c683da532e8037820119-v1.14   "/sbin/dind_init sys…"   2 minutes ago   Up 2 minutes   8080/tcp                    kube-node-2
d654528606b7   mirantis/kubeadm-dind-cluster:814d9ca036b23adce9e6c683da532e8037820119-v1.14   "/sbin/dind_init sys…"   2 minutes ago   Up 2 minutes   8080/tcp                    kube-node-1
54bfbd474d33   mirantis/kubeadm-dind-cluster:814d9ca036b23adce9e6c683da532e8037820119-v1.14   "/sbin/dind_init sys…"   4 minutes ago   Up 4 minutes   127.0.0.1:32768->8080/tcp   kube-master
```

```bash
[root@ip-172-31-94-118 ~]# kubectl get nodes
NAME          STATUS   ROLES    AGE     VERSION
kube-master   Ready    master   5m39s   v1.14.1
kube-node-1   Ready    <none>   4m19s   v1.14.1
kube-node-2   Ready    <none>   4m19s   v1.14.1
```

## End-to-End Bank Application Deployment using DevSecOps on AWS EKS
This is a multi-tier bank an application written in Java (Springboot).


### 🔧 Tech stack used in this project:

| Tool        | Purpose                                  |
|-------------|------------------------------------------|
| GitHub      | Source code repository                   |
| Jenkins     | CI/CD pipeline automation                |
| OWASP       | Dependency vulnerability check           |
| SonarQube   | Code quality and static analysis         |
| Trivy       | Filesystem and Docker image scanning     |
| Docker      | Containerization                         |
| Helm        | Kubernetes package manager               |
| ArgoCD      | GitOps-based continuous delivery         |
| AWS EKS     | Container orchestration                  |
| Prometheus  | Monitoring                               |
| Grafana     | Dashboards and visualization             |
| Gmail       | Email notifications                      |


### Steps to deploy:
1. Create 1 Master machine on AWS (t2.medium) and 29 GB of storage.
2. Open the below ports in security group

| Type  | Port Range |
| ------------- | ------------- |
| Custom TCP  | 30000 - 32767  |
| HTTP        | 80  |
| Custom TCP  | 6379  |
| HTTPS       | 443  |
| SMTPS       | 465  |
| Custom TCP  | 3000 - 10000  |
| SSH         | 22  |
| SMTP        | 25  |
| Custom TCP   6443  |  

3. Create EKS Cluster on AWS
4. IAM user with access keys and secret access keys
5. AWSCLI should be configured <a href="https://github.com/vinayakz/DevOps-Starter-Pack-Installing-the-Most-Important-Tools-on-Ubuntu-Linux">(Setup AWSCLI)</a>

```sh
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    sudo apt install unzip
    unzip awscliv2.zip
    sudo ./aws/install
    aws configure
```

6. Install kubectl

```sh
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

7. Install eksctl

```sh
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
```

8. Create EKS Cluster

```sh
eksctl create cluster --name=java-bank-app \
                    --region=ap-south-1 \
                    --version=1.30 \
                    --without-nodegroup
```

9. Associate IAM OIDC Provider

```sh
eksctl utils associate-iam-oidc-provider \
  --region ap-south-1 \
  --cluster java-bank-app \
  --approve
```

10. Create Nodegroup
```sh
eksctl create nodegroup --cluster=bankapp \
                     --region=ap-south-1 \
                     --name=java-bank-app \
                     --node-type=t2.medium \
                     --nodes=2 \
                     --nodes-min=2 \
                     --nodes-max=2 \
                     --node-volume-size=29 \
                     --ssh-access \
                     --ssh-public-key=eks-nodegroup-key 
```
> [!NOTE]  
> Make sure the ssh-public-key "eks-nodegroup-key is available in your aws account"

11. Install Jenkins
```sh
sudo apt update -y
sudo apt install fontconfig openjdk-17-jre -y

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
sudo apt-get install jenkins
```

- After installing Jenkins, change the default port of jenkins from 8080 to 8081. Because our bankapp application will be running on 8080.

```sh
Open /usr/lib/systemd/system/jenkins.service file and change JENKINS_PORT environment variable
Like This :- Environment="JENKINS_PORTS=8081"
```
- Reload daemon

```sh
sudo systemctl daemon-reload 
```
- Restart Jenkins

```sh
sudo systemctl restart jenkins
```

12. Install docker

```sh
sudo apt install docker.io -y
sudo usermod -aG docker ubuntu && newgrp docker
```

13. Install and configure SonarQube

```sh
docker run -itd --name SonarQube-Server -p 9000:9000 sonarqube:lts-community
```

14. Install Trivy

```sh
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update -y
sudo apt-get install trivy -y
```
- Install and Configure ArgoCD
    - Create argocd namespace

```sh
kubectl create namespace argocd
```

- Apply argocd manifest
```sh
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```
- Make sure all pods are running in argocd namespace
```sh
watch kubectl get pods -n argocd
```
- Install argocd CLI
```sh
curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.7/argocd-linux-amd64
```

- Provide executable permission
```sh
chmod +x /usr/local/bin/argocd
```

- Check argocd services
```sh
kubectl get svc -n argocd
```

- Change argocd server's service from ClusterIP to NodePort
```sh
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

- Confirm service is patched or not
```sh
kubectl get svc -n argocd
```

- Access it on browser, click on advance and proceed with
```sh
Public-ip-workernode>:<port>
```

- Fetch the initial password of argocd server
```sh
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```
- Username: admin
- Now, go to User Info and update your argocd password

15. How to monitor EKS cluster, kubernetes components and workloads using prometheus and grafana via HELM (On Master machine)

- Install Helm Chart
```sh
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

- Add Helm Stable Charts for Your Local Client
```sh
helm repo add stable https://charts.helm.sh/stable
```

- Add Prometheus Helm Repository
```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
```

16. Create Prometheus Namespace
```sh
kubectl create namespace prometheus
```
```sh
kubectl get ns
```

17. Install Prometheus using Helm
```sh
helm install stable prometheus-community/kube-prometheus-stack -n prometheus
```

- Verify prometheus installation
```sh
kubectl get pods -n prometheus
```
- Check the services file (svc) of the Prometheus
```sh
kubectl get svc -n prometheus
```

- Verify service
```sh
kubectl get svc -n prometheus
```

- Check grafana service
```sh
kubectl get svc -n prometheus
```

- Get a password for grafana
```sh
kubectl get secret --namespace prometheus stable-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

Username: admin
```

## Clean Up

- Delete eks cluster
```sh
eksctl delete cluster --name=bankapp --region=us-west-1
```

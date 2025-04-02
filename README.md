# AWS Nginx Deployment with Terraform and Ansible

## Project Description
This project automates the deployment of a secure Nginx web server on AWS using:
- **Terraform** for infrastructure provisioning (EC2, VPC, DNS)
- **Ansible** for server configuration and application deployment

## Prerequisites
- AWS account with admin permissions
- Terraform 1.0+ installed
- Ansible 2.10+ installed
- AWS CLI configured with credentials
- SSH key pair (~/.ssh/id_rsa)


## 🚀 Deployment

### Prerequisites
- AWS account with IAM permissions
- Terraform v1.0+ and Ansible installed
- SSH key pair (`~/.ssh/id_rsa.pub`)


## Getting Started

### 1. Clone the repository
```bash
git clone https://github.com/basilmakama/terraform-ansible-nginx.git
cd terraform-ansible-nginx

### 2. Terraform Deployment
cd terraform
cp terraform.tfvars.example terraform.tfvars  # Update with your values
terraform init
terraform plan
terraform apply -auto-approve

### 2. Ansible Configuration
cd ../ansible
ansible-playbook -i inventory.ini playbook.yaml

##Key Components

Terraform Resources:

- EC2 Instance: Ubuntu server with Nginx
- VPC: Isolated network environment  
- Route 53: Private DNS zone for internal resolution
- Security Groups: Restrict access to HTTP/HTTPS/SSH

Ansible Tasks:

- Install and configure Nginx
- Set up firewall rules
- Deploy custom index page  

Security Notes:

- All sensitive files are excluded via .gitignore
- IAM follows principle of least privilege
- Private DNS zone only accessible within VPC
- SSH access restricted to specified IPs
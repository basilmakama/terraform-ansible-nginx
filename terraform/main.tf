# Locks versions to prevent unexpected compatibility issues
terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

# VPC where all resources will live
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/24"
  enable_dns_support = true    
  enable_dns_hostnames = true  
  tags = {
    Name = "nginx-vpc"  
  }
}

# Create a public subnet within the VPC
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  
  cidr_block = "10.0.0.0/26" 
  map_public_ip_on_launch = true 
  availability_zone = "${var.region}a"  
  tags = {
    Name = "nginx-public-subnet"  
  }
}

# Internet Gateway for communication between VPC and the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id 
  tags = {
    Name = "nginx-igw"  # Tag
  }
}

# Route Table for public traffic
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id  

  # Sends all traffic to the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"  # All IPv4 addresses
    gateway_id = aws_internet_gateway.gw.id  # Points to our IGW
  }
  tags = {
    Name = "nginx-public-rt" 
  }
}

# Associate the public subnet with the route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id      # Public subnet
  route_table_id = aws_route_table.public.id # Public route table
}

# Security Group Controls for EC2
resource "aws_security_group" "nginx" {
  name        = "nginx-sg" 
  description = "Allow HTTPS and limited SSH access"
  vpc_id      = aws_vpc.main.id  # Attaches to our VPC

  # HTTPS (port 443) from anywhere
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443       # HTTPS port
    to_port     = 443       
    protocol    = "tcp"      # TCP protocol for web traffic
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Restricted SSH access
  ingress {
    description = "SSH from specific IP"
    from_port   = 22        # SSH port
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_ip]  # From variables.tf
  }
  
  # HTTP access for Let's Encrypt verification
 ingress {
    description = "HTTP"
    from_port   = 80        
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0        
    to_port     = 0         
    protocol    = "-1"      # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # To all IPs
  }

  tags = {
    Name = "nginx-sg" 
  }
}

# Create the EC2 instance
resource "aws_instance" "nginx" {
  ami           = data.aws_ami.ubuntu.id  
  instance_type = var.instance_type       
  subnet_id     = aws_subnet.public.id    
  vpc_security_group_ids = [aws_security_group.nginx.id]  # Applies our security group
  key_name      = aws_key_pair.nginx.key_name  # SSH key for access

  # User data script that runs when instance first launches
  # Installs Python3 which is required for Ansible to work
  user_data = <<-EOF
               #!/bin/bash
                apt-get update
                apt-get install -y python3 python3-pip software-properties-common
                add-apt-repository --yes --update ppa:ansible/ansible
                apt-get install -y ansible
                # Create ansible user
                useradd -m -s /bin/bash ansible
                mkdir -p /home/ansible/.ssh
                cp /home/ubuntu/.ssh/authorized_keys /home/ansible/.ssh/
                chown -R ansible:ansible /home/ansible/.ssh
                EOF

  tags = {
    Name = "nginx-server" 
  }
}

# SSH key pair for secure access
resource "aws_key_pair" "nginx" {
  key_name   = "nginx-key"                
  public_key = file(var.public_key_path)  # Path to your local public key
}

# Create an Internal Route53 DNS zone
resource "aws_route53_zone" "internal" {
  name    = var.internal_domain  # Domain name (from variables.tf)
  comment = "Internal zone for nginx server"
  # Associates this DNS zone with our VPC
  vpc {
    vpc_id = aws_vpc.main.id
  }
}

# Create a DNS A record pointing to our EC2 instance
resource "aws_route53_record" "nginx" {
  zone_id = aws_route53_zone.internal.zone_id  
  name    = "${var.subdomain}.${var.internal_domain}"      
  type    = "A"                                
  ttl     = "300"                              
  records = [aws_instance.nginx.private_ip]    
}

# Data source to find the latest Ubuntu 20.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true  

  # Filter for Ubuntu 20.04 images
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  # Filter for HVM virtualization type
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Official Canonical (Ubuntu) account ID
  owners = ["099720109477"]
}

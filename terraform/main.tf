# Configure the AWS Provider
provider "aws" {
  region = var.region  # The region is set in variables.tf
}

# VPC where all resources will live
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"  # 65536 private IP addresses available
  enable_dns_support = true    # Required for DNS resolution
  enable_dns_hostnames = true  # Gives instances DNS names
  tags = {
    Name = "nginx-vpc"  
  }
}

# Create a public subnet within the VPC
# Public subnets can communicate with the internet
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id  # Attaches to our VPC
  cidr_block = "10.0.1.0/24"    # 256 IP addresses in this subnet
  map_public_ip_on_launch = true # Automatically assigns public IPs
  availability_zone = "${var.region}a"  # Places in first AZ of the region
  tags = {
    Name = "nginx-public-subnet"  # Tag
  }
}

# Create an Internet Gateway that allows communication between our VPC and the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id  # Attaches to our VPC
  tags = {
    Name = "nginx-igw"  # Tag
  }
}

# Create a Route Table for public traffic
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id  # Associated with our VPC

  # Sends all traffic to the Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"  # All IPv4 addresses
    gateway_id = aws_internet_gateway.gw.id  # Points to our IGW
  }

  tags = {
    Name = "nginx-public-rt"  # Tag
  }
}

# Associate the public subnet with the route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id      # Public subnet
  route_table_id = aws_route_table.public.id # Public route table
}

# Security Group Controls inbound and outbound traffic to our EC2 instance
resource "aws_security_group" "nginx" {
  name        = "nginx-sg" 
  description = "Allow HTTPS and limited SSH access"
  vpc_id      = aws_vpc.main.id  # Attaches to our VPC

  # Inbound rule: Allow HTTPS (port 443) from anywhere
  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443       # HTTPS port
    to_port     = 443       # Same as from_port for single port
    protocol    = "tcp"      # TCP protocol for web traffic
    cidr_blocks = ["0.0.0.0/0"]  # Allow from all IPs
  }

  # Inbound rule: Allow SSH (port 22) only from specified IP
  ingress {
    description = "SSH from specific IP"
    from_port   = 22        # SSH port
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_ip]  # From variables.tf
  }

  # Outbound rule: Allow all outbound traffic
  egress {
    from_port   = 0        
    to_port     = 0         
    protocol    = "-1"      # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # To all IPs
  }

  tags = {
    Name = "nginx-sg"  # Tag
  }
}

# Create the EC2 instance
resource "aws_instance" "nginx" {
  ami           = data.aws_ami.ubuntu.id  # Uses latest Ubuntu AMI
  instance_type = var.instance_type       # Instance type
  subnet_id     = aws_subnet.public.id    # Places in public subnet
  vpc_security_group_ids = [aws_security_group.nginx.id]  # Applies our security group
  key_name      = aws_key_pair.nginx.key_name  # SSH key for access

  # User data script that runs when instance first launches
  # Installs Python3 which is required for Ansible to work
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y python3
              EOF

  tags = {
    Name = "nginx-server"  # Tag
  }
}

# Create an SSH key pair for secure access
resource "aws_key_pair" "nginx" {
  key_name   = "nginx-key"                # Name of key in AWS
  public_key = file(var.public_key_path)  # Path to your local public key
}

# Create a private Route53 DNS zone
# This will only be accessible within our VPC
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
  zone_id = aws_route53_zone.internal.zone_id  # Our private zone
  name    = "nginx.${var.internal_domain}"     # Subdomain (nginx.internal.example.com)
  type    = "A"                                # IPv4 address record
  ttl     = "300"                              # Time-to-live in seconds
  records = [aws_instance.nginx.private_ip]    # Points to EC2's private IP
}

# Data source to find the latest Ubuntu 20.04 AMI
# This ensures we always use an up-to-date image
data "aws_ami" "ubuntu" {
  most_recent = true  # Get the newest AMI

  # Filter for Ubuntu 20.04 images
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  # Filter for HVM virtualization type (better performance)
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  # Official Canonical (Ubuntu) account ID
  owners = ["099720109477"]
}

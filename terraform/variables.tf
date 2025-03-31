# AWS region where resources will be deployed
# Default is 'us-east-1' but can be overridden
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

# EC2 instance type
variable "instance_type" {
  description = "Instance to launch"
  type        = string
  default     = "t2.micro"
}

# Path to your PUBLIC SSH key, will be uploaded to AWS for EC2 access
variable "public_key_path" {
  description = "~/.ssh/id_rsa.pub"
  type        = string
  # No default - must be provided via terraform.tfvars or CLI
}

# IP address allowed to SSH into the instance
# Security best practice: Restrict to your IP
variable "allowed_ssh_ip" {
  description = "Your public IP in CIDR notation (e.g., 203.0.113.25/32)"
  type        = string
  default     = "0.0.0.0/0"  # WARNING: Leaving this open is insecure!
}

# Internal domain name for Route53
# Will only resolve within the VPC
variable "internal_domain" {
  description = "Internal domain name"
  type        = string
  default     = "internal.basil.com"  # Change to your preferred domain
}
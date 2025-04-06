# AWS region where resources will be deployed
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

# Path to your PUBLIC SSH key
variable "public_key_path" {
  description = "~/.ssh/id_rsa.pub"
  type        = string
}

# IP address allowed to SSH into the instance
variable "allowed_ssh_ip" {
  description = "Your public IP in CIDR notation (e.g., 203.0.113.25/32)"
  type        = string
  default     = "0.0.0.0/0"
}

# Internal domain name for Route53
variable "internal_domain" {
  description = "Internal domain name"
  type        = string
  default     = "senrep.internal"
}

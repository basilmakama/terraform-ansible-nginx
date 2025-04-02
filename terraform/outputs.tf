
# EC2 Instance Public IP
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance for web access"
  value       = aws_instance.nginx.public_ip  # Reference to the EC2's public IP
  sensitive   = false
}

# Internal Route53 DNS Name
output "internal_domain" {
  description = "Internal DNS name (resolves only within the VPC)"
  value       = aws_route53_record.nginx.fqdn
}

# VPC ID
output "vpc_id" {
  description = "ID of the created VPC for reference"
  value       = aws_vpc.main.id
  sensitive   = true
}


# This now EXECUTES the inventory update
output "update_inventory" {
  value = <<-EOT
    #!/bin/bash
    set -e
    mkdir -p ${path.module}/../ansible
    echo "[webservers]" > ${path.module}/../ansible/inventory.ini
    echo "${aws_instance.nginx.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=${replace(var.public_key_path, ".pub", "")}" >> ${path.module}/../ansible/inventory.ini
    echo -e "\n[webservers:vars]\ndomain=${aws_route53_record.nginx.name}" >> ${path.module}/../ansible/inventory.ini
    echo "Inventory updated with IP ${aws_instance.nginx.public_ip}"
  EOT
}
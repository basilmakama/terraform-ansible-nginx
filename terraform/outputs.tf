
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

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance (for internal communication)"
  value       = aws_instance.nginx.private_ip
  sensitive   = true
}

output "public_dns_name" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.nginx.public_dns
}

# VPC ID
output "vpc_id" {
  description = "ID of the created VPC for reference"
  value       = aws_vpc.main.id
  sensitive   = true
}

output "nginx_access_url" {
  description = "URL to access the Nginx server"
  value       = "https://${aws_instance.nginx.public_ip}"
}

output "ssh_access_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${replace(var.public_key_path, ".pub", "")} ubuntu@${aws_instance.nginx.public_ip}"
  sensitive   = true
}


# Creates a self-updating ansible file
output "update_inventory" {
  value = <<-EOT
    #!/bin/bash
    set -eo pipefail
    
    # Configurable paths
    INVENTORY_DIR="${path.module}/../ansible"
    INVENTORY_FILE="$INVENTORY_DIR/inventory.ini"
    PRIVATE_KEY="${replace(var.public_key_path, ".pub", "")}"
    
    # Ensure directory exists
    mkdir -p "$INVENTORY_DIR"
    
    # Write inventory header
    cat > "$INVENTORY_FILE" <<EOF
    [webservers]
    ${aws_instance.nginx.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=$PRIVATE_KEY
    
    [webservers:vars]
    internal_dns=${aws_route53_record.nginx.fqdn}
    public_ip=${aws_instance.nginx.public_ip}
    EOF
    
    # Post-generation validation
    if [ ! -f "$PRIVATE_KEY" ]; then
      echo "SSH private key not found at $PRIVATE_KEY" >&2
    fi
    
    echo "Ansible inventory updated:"
    cat "$INVENTORY_FILE"
  EOT
}

# Verification Command
output "verify_nginx_command" {
  description = "Command to verify Nginx is running"
  value       = "curl -sI https://${aws_instance.nginx.public_ip} | grep 'HTTP/.*200'"
}
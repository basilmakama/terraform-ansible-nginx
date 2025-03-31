
# Output: EC2 Instance Public IP
# This is the public IP address assigned to your Nginx server
output "instance_public_ip" {
  description = "Public IP address of the EC2 instance for web access"
  value       = aws_instance.nginx.public_ip  # Reference to the EC2's public IP
  sensitive   = false  # This can be shown in logs (not a secret)
}

# Output: Internal Route53 DNS Name
# The fully qualified domain name (FQDN) for internal VPC communication
output "internal_domain" {
  description = "Internal DNS name (resolves only within the VPC)"
  value       = aws_route53_record.nginx.fqdn
}

# Output: VPC ID
# Useful for debugging or expanding your infrastructure later
output "vpc_id" {
  description = "ID of the created VPC for reference"
  value       = aws_vpc.main.id
  sensitive   = true  # Marks as sensitive (not shown in plaintext logs)
}
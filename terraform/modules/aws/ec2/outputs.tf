output "id" {
  description = "The ID of the instance."
  value       = aws_instance.this.id
}

output "arn" {
  description = "The ARN of the instance."
  value       = aws_instance.this.arn
}

output "private_ip" {
  description = "The private IP address assigned to the instance."
  value       = aws_instance.this.private_ip
}

output "public_ip" {
  description = "The public IP address assigned to the instance, if applicable."
  value       = aws_instance.this.public_ip
}

output "primary_network_interface_id" {
  description = "The ID of the instance's primary network interface."
  value       = aws_instance.this.primary_network_interface_id
}

output "private_dns" {
  description = "The private DNS name assigned to the instance."
  value       = aws_instance.this.private_dns
}

output "public_dns" {
  description = "The public DNS name assigned to the instance."
  value       = aws_instance.this.public_dns
}

output "availability_zone" {
  description = "The availability zone of the instance."
  value       = aws_instance.this.availability_zone
}

output "subnet_id" {
  description = "The VPC Subnet ID in which the instance was launched."
  value       = aws_instance.this.subnet_id
}

output "instance_state" {
  description = "The current state of the instance."
  value       = aws_instance.this.instance_state
}

output "tags_all" {
  description = "A map of tags assigned to the resource, including inherited provider default tags."
  value       = aws_instance.this.tags_all
}

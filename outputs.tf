output "gcp_lb_ip_address" {
  description = "Global external IPv4 address of the GCP Load Balancer."
  value       = module.gcp_lb.lb_ip_address
}

output "gcp_hybrid_neg_id" {
  description = "Resource ID of the GCP Hybrid Network Endpoint Group."
  value       = module.hybrid_neg.neg_id
}

output "gcp_hybrid_neg_name" {
  description = "Name of the GCP Hybrid Network Endpoint Group."
  value       = module.hybrid_neg.neg_name
}

output "registered_hybrid_endpoints" {
  description = "Target private IP endpoints in AWS registered with the GCP Hybrid NEG."
  value       = var.hybrid_neg_endpoints
}

output "aws_internal_alb_dns_name" {
  description = "DNS name of the AWS Internal Application Load Balancer."
  value       = module.internal_alb.dns_name
}

output "aws_internal_alb_arn" {
  description = "ARN of the AWS Internal Application Load Balancer."
  value       = module.internal_alb.arn
}


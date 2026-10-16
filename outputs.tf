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
  description = "AWS NLB static private IPs registered with the GCP Hybrid NEG."
  value       = local.hybrid_neg_endpoints
}

output "aws_internal_nlb_dns_name" {
  description = "DNS name of the AWS internal Network Load Balancer."
  value       = module.internal_nlb.dns_name
}

output "aws_internal_nlb_arn" {
  description = "ARN of the AWS internal Network Load Balancer."
  value       = module.internal_nlb.arn
}

output "bgp_status_command" {
  description = "Command to verify all four BGP sessions are Established."
  value       = "gcloud compute routers get-status ${google_compute_router.router.name} --region ${var.gcp_region} --project ${var.gcp_project_id}"
}
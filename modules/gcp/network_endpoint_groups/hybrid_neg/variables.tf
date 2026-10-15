variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "name" {
  description = "Name of the Hybrid Network Endpoint Group."
  type        = string
}

variable "network" {
  description = "The VPC network name or self_link where the endpoints are reachable."
  type        = string
}

variable "subnetwork" {
  description = "The VPC subnetwork name or self_link where the endpoints are reachable."
  type        = string
}

variable "zone" {
  description = "The GCP zone where the Hybrid NEG will be created."
  type        = string
}

variable "default_port" {
  description = "The default port used if not specified in the endpoints configuration."
  type        = number
  default     = 80
}

variable "endpoints" {
  description = "List of hybrid endpoints (IP and Port) to register with the NEG."
  type = list(object({
    ip_address = string
    port       = optional(number)
  }))
  default = []
}
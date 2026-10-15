variable "project_id" {
  type        = string
  description = "The ID of the GCP project where resources will be created."
}

variable "neg_name" {
  type        = string
  description = "The name of the Zonal Network Endpoint Group."
}

variable "description" {
  type        = string
  default     = null
  description = "An optional description of this NEG."
}

variable "network" {
  type        = string
  description = "The VPC network name or self_link where the endpoints reside."
}

variable "subnetwork" {
  type        = string
  default     = null
  description = "Optional VPC subnetwork name or self_link."
}

variable "zone" {
  type        = string
  description = "The specific GCP zone where the NEG and its target VMs reside (e.g., us-central1-a)."
}

variable "default_port" {
  type        = number
  default     = 80
  description = "The default port used if not specified on individual endpoints."
}

variable "endpoints" {
  type = list(object({
    instance   = string          # The name or self-link of the GCE VM instance
    ip_address = optional(string) # Optional internal IP. If blank, GCP resolves to the primary internal IP of the VM.
    port       = optional(number) # Optional port override. If blank, falls back to default_port.
  }))
  default     = []
  description = "List of GCE VM instances and ports to attach to this Zonal NEG."
}
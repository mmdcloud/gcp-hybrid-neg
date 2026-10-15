variable "project_id" {
  type        = string
  description = "The ID of the GCP project where the Internet NEG will be created."
}

variable "neg_name" {
  type        = string
  description = "The name of the Internet Network Endpoint Group."
}

variable "description" {
  type        = string
  default     = null
  description = "An optional description of this NEG."
}

variable "is_global" {
  type        = bool
  default     = true
  description = "Set to true to create a Global Internet NEG. Set to false to create a Regional Internet NEG."
}

variable "region" {
  type        = string
  default     = null
  description = "The target GCP region. Required only if is_global is set to false (Regional NEG)."
}

variable "endpoints" {
  type = list(object({
    fqdn       = optional(string)
    ip_address = optional(string)
    port       = optional(number)
  }))
  default     = []
  description = "List of public internet endpoints (FQDN or IP, and Port) to register with the NEG."

  validation {
    condition = alltrue([
      for e in var.endpoints : (e.fqdn != null && e.ip_address == null) || (e.fqdn == null && e.ip_address != null)
    ])
    error_message = "CRITICAL ERROR: Each endpoint must define either an 'fqdn' or an 'ip_address', but not both."
  }
}

variable "project_id" {
  type        = string
  description = "The ID of the GCP project where resources will be provisioned."
}

variable "neg_name" {
  type        = string
  description = "The name of the Serverless Network Endpoint Group."
}

variable "description" {
  type        = string
  default     = null
  description = "An optional textual description of the resource."
}

variable "region" {
  type        = string
  description = "The GCP region where the Serverless NEG will reside (e.g., us-central1)."
}

variable "network" {
  type        = string
  default     = null
  description = "Optional VPC network self-link."
}

variable "subnetwork" {
  type        = string
  default     = null
  description = "Optional VPC subnetwork self-link."
}

variable "cloud_run" {
  type = object({
    service  = optional(string)
    tag      = optional(string)
    url_mask = optional(string)
  })
  default = null
}

variable "cloud_function" {
  type = object({
    function = optional(string)
    url_mask = optional(string)
  })
  default = null
}

variable "app_engine" {
  type = object({
    service  = optional(string)
    version  = optional(string)
    url_mask = optional(string)
  })
  default = null
}
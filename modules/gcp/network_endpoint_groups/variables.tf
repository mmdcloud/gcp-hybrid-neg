variable "type" {
  description = "Type of the regional network endpoint group."
  type        = string
}

variable "default_port" {
  description = "Default port of the regional network endpoint group."
  type        = string
  default     = null
}

variable "zone" {
  description = "Zone of the regional network endpoint group."
  type        = string
  default     = null
}

variable "neg_name" {
  description = "Name of the regional network endpoint group."
  type        = string
}

variable "description" {
  description = "Description of the network endpoint group."
  type        = string
  default     = ""
}

variable "neg_type" {
  description = "Type of network endpoint group. One of: SERVERLESS, PRIVATE_SERVICE_CONNECT, INTERNET_IP_PORT, INTERNET_FQDN_PORT, NON_GCP_PRIVATE_IP_PORT."
  type        = string
  
}

variable "location" {
  description = "Region in which to create the network endpoint group."
  type        = string
}

variable "network" {
  description = "Self link of the VPC network to which the NEG belongs. Required for PSC NEGs, optional for most serverless NEGs."
  type        = string
  default     = null
}

variable "subnetwork" {
  description = "Self link of the subnetwork to which the NEG belongs. Required for PSC NEGs."
  type        = string
  default     = null
}

variable "cloud_run" {
  description = "Cloud Run service to target. Only one of cloud_run, cloud_function, app_engine, or psc_data should be set."
  type = object({
    service  = optional(string)
    tag      = optional(string)
    url_mask = optional(string)
  })
  default = null
}

variable "cloud_function" {
  description = "Cloud Function to target. Only one of cloud_run, cloud_function, app_engine, or psc_data should be set."
  type = object({
    function = optional(string)
    url_mask = optional(string)
  })
  default = null
}

variable "app_engine" {
  description = "App Engine service to target. Only one of cloud_run, cloud_function, app_engine, or psc_data should be set."
  type = object({
    service  = optional(string)
    version  = optional(string)
    url_mask = optional(string)
  })
  default = null
}

variable "psc_data" {
  description = "Private Service Connect data, used when neg_type is PRIVATE_SERVICE_CONNECT."
  type = object({
    producer_port = optional(number)
  })
  default = null
}

variable "psc_target_service" {
  description = "Target service for Private Service Connect NEGs, e.g. the PSC service attachment URI."
  type        = string
  default     = null
}
variable "psk_length" {
  type        = number
  description = "Length of the generated pre-shared keys. Default is 32 characters for high entropy."
  default     = 32

  validation {
    condition     = var.psk_length >= 24 && var.psk_length <= 128
    error_message = "PSK length must be between 24 and 128 characters for production security standards."
  }
}

variable "custom_psk_1" {
  type        = string
  description = "Optional custom PSK for Tunnel 1. If provided, overrides auto-generated secret."
  default     = ""
  sensitive   = true
}

variable "custom_psk_2" {
  type        = string
  description = "Optional custom PSK for Tunnel 2. If provided, overrides auto-generated secret."
  default     = ""
  sensitive   = true
}


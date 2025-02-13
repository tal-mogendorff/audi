# 🔌 Jenkins Configuration
variable "openshift_url" {
  description = "🌐 OpenShift URL (e.g., http://jenkins.example.com:8080)"
  type        = string

  validation {
    condition     = can(regex("^(http|https)://", var.openshift_url))
    error_message = "🚫 OpenShift URL must start with http:// or https://"
  }
}

variable "openshift_username" {
  description = "👤 OpenShift username for Cluster access"
  type        = string
  default     = ""
}


variable "openshift_password" {
  description = "🔑 OpenShift password for authentication (sensitive)"
  type        = string
  sensitive   = true
}

variable "kubiya_runner" {
  description = "🏃 Infrastructure runner that will execute the OpenShift operations"
  type        = string
}

# Define input variables for the configuration

# Variable for location
variable "location" {
  description = "The Azure region to deploy resources in."
  type        = string
  default     = "East US"
}

# Variable for VM admin password
variable "admin_password" {
  description = "The password for the VM administrator."
  type        = string
  sensitive   = true
}

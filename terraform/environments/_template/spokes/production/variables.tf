variable "customer_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "spoke_name" {
  type    = string
  default = "production"
}

variable "region" {
  type = string
}

variable "region_code" {
  type = string
}

variable "spoke_vnet_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

# Service toggles (customer selects in portal)
variable "enable_sql" {
  type    = bool
  default = false
}

variable "enable_keyvault" {
  type    = bool
  default = false
}

variable "enable_storage" {
  type    = bool
  default = false
}

variable "enable_datafactory" {
  type    = bool
  default = false
}

# SQL configuration
variable "sql_database_name" {
  type    = string
  default = "app-db"
}

variable "sql_admin_password" {
  type      = string
  sensitive = true
  default   = null
}
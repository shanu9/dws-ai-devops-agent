variable "customer_id" {
  type = string
}

variable "environment" {
  type    = string
  default = "prd"
}

variable "region" {
  type = string
}

variable "region_code" {
  type = string
}

variable "alert_email_receivers" {
  description = "List of emails for alerts"
  type        = list(string)
}

variable "monthly_budget" {
  description = "Monthly budget in USD"
  type        = number
  default     = 0
}
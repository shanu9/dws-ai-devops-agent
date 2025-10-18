# =============================================================================
# COGNITIVE SERVICES MODULE VARIABLES
# =============================================================================

variable "customer_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "spoke_name" {
  type = string
}

variable "region" {
  type = string
}

variable "region_code" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "cognitive_account_name" {
  type    = string
  default = null
}

variable "kind" {
  description = "Cognitive Services kind"
  type        = string
  validation {
    condition = contains([
      "AnomalyDetector", "ComputerVision", "ContentModerator", "CustomVision.Prediction",
      "CustomVision.Training", "Face", "FormRecognizer", "ImmersiveReader", "LUIS",
      "LUIS.Authoring", "OpenAI", "Personalizer", "SpeechServices", "TextAnalytics",
      "TextTranslation", "CognitiveServices"
    ], var.kind)
    error_message = "Must be valid Cognitive Services kind."
  }
}

variable "sku_name" {
  description = "SKU name (F0=Free, S0=Standard)"
  type        = string
  default     = "S0"
  validation {
    condition     = can(regex("^(F0|S0|S1|S2|S3|S4)$", var.sku_name))
    error_message = "Must be F0, S0, S1, S2, S3, or S4."
  }
}

variable "custom_subdomain_name" {
  description = "Custom subdomain name (required for private endpoints)"
  type        = string
  default     = null
}

variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "allowed_ip_ranges" {
  type    = list(string)
  default = []
}

variable "allowed_subnet_ids" {
  type    = list(string)
  default = []
}

variable "enable_local_authentication" {
  description = "Enable API key authentication"
  type        = bool
  default     = true
}

variable "restrict_outbound_network_access" {
  type    = bool
  default = false
}

variable "enable_dynamic_throttling" {
  type    = bool
  default = false
}

variable "customer_managed_key_id" {
  type    = string
  default = null
}

variable "key_vault_identity_client_id" {
  type    = string
  default = null
}

variable "openai_deployments" {
  description = "OpenAI model deployments (if kind is OpenAI)"
  type = map(object({
    model_format   = string
    model_name     = string
    model_version  = string
    scale_type     = string
    capacity       = number
    rai_policy_name = string
  }))
  default = {}
  # Example:
  # {
  #   "gpt-4" = {
  #     model_format    = "OpenAI"
  #     model_name      = "gpt-4"
  #     model_version   = "0613"
  #     scale_type      = "Standard"
  #     capacity        = 10
  #     rai_policy_name = null
  #   }
  # }
}

variable "enable_private_endpoint" {
  type    = bool
  default = true
}

variable "subnet_id" {
  type    = string
  default = null
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "cost_center" {
  type    = string
  default = "AI-Services"
}

variable "team" {
  type    = string
  default = "AI-Engineering"
}

variable "tags" {
  type    = map(string)
  default = {}
}
# =============================================================================
# MACHINE LEARNING MODULE VARIABLES
# =============================================================================

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "customer_id" {
  description = "Unique customer identifier"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9]{3,6}$", var.customer_id))
    error_message = "Customer ID must be 3-6 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Environment (dev/stg/prd)"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "prd"], var.environment)
    error_message = "Environment must be dev, stg, or prd."
  }
}

variable "spoke_name" {
  description = "Spoke name"
  type        = string
}

variable "region" {
  description = "Azure region"
  type        = string
}

variable "region_code" {
  description = "Short region code"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

# -----------------------------------------------------------------------------
# ML WORKSPACE CONFIGURATION
# -----------------------------------------------------------------------------

variable "ml_workspace_name" {
  description = "ML workspace name (auto-generated if not provided)"
  type        = string
  default     = null
}

variable "enable_hbi_workspace" {
  description = "Enable High Business Impact workspace (enhanced security)"
  type        = bool
  default     = false
}

variable "public_network_access_enabled" {
  description = "Enable public network access"
  type        = bool
  default     = false
}

variable "customer_managed_key_id" {
  description = "Customer managed key ID for encryption"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# STORAGE CONFIGURATION
# -----------------------------------------------------------------------------

variable "storage_replication_type" {
  description = "Storage replication type"
  type        = string
  default     = "GRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS"], var.storage_replication_type)
    error_message = "Must be LRS, GRS, RAGRS, or ZRS."
  }
}

# -----------------------------------------------------------------------------
# CONTAINER REGISTRY
# -----------------------------------------------------------------------------

variable "enable_container_registry" {
  description = "Create Container Registry for custom environments"
  type        = bool
  default     = true
}

variable "container_registry_sku" {
  description = "Container Registry SKU"
  type        = string
  default     = "Premium" # Required for private endpoints
  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.container_registry_sku)
    error_message = "Must be Basic, Standard, or Premium."
  }
}

# -----------------------------------------------------------------------------
# KEY VAULT CONFIGURATION
# -----------------------------------------------------------------------------

variable "enable_purge_protection" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# COMPUTE CLUSTERS (For training)
# -----------------------------------------------------------------------------

variable "compute_clusters" {
  description = "Map of compute clusters to create"
  type = map(object({
    vm_size                        = string
    vm_priority                    = string
    min_nodes                      = number
    max_nodes                      = number
    idle_seconds_before_scaledown  = string
    subnet_id                      = string
    enable_ssh                     = bool
    ssh_admin_username             = string
    ssh_admin_password             = string
    description                    = string
  }))
  default = {}
  # Example:
  # {
  #   "cpu-cluster" = {
  #     vm_size                       = "STANDARD_DS3_V2"
  #     vm_priority                   = "LowPriority"
  #     min_nodes                     = 0
  #     max_nodes                     = 4
  #     idle_seconds_before_scaledown = "PT120S"
  #     subnet_id                     = null
  #     enable_ssh                    = false
  #     ssh_admin_username            = null
  #     ssh_admin_password            = null
  #     description                   = "CPU cluster for training"
  #   },
  #   "gpu-cluster" = {
  #     vm_size                       = "STANDARD_NC6"
  #     vm_priority                   = "Dedicated"
  #     min_nodes                     = 0
  #     max_nodes                     = 2
  #     idle_seconds_before_scaledown = "PT300S"
  #     subnet_id                     = null
  #     enable_ssh                    = false
  #     ssh_admin_username            = null
  #     ssh_admin_password            = null
  #     description                   = "GPU cluster for deep learning"
  #   }
  # }
}

# -----------------------------------------------------------------------------
# COMPUTE INSTANCES (For development)
# -----------------------------------------------------------------------------

variable "compute_instances" {
  description = "Map of compute instances to create"
  type = map(object({
    vm_size                  = string
    assigned_user_object_id  = string
    subnet_id                = string
    enable_ssh               = bool
    ssh_public_key           = string
    description              = string
  }))
  default = {}
  # Example:
  # {
  #   "dev-instance" = {
  #     vm_size                 = "STANDARD_DS3_V2"
  #     assigned_user_object_id = "user-aad-object-id"
  #     subnet_id               = "/subscriptions/..."
  #     enable_ssh              = true
  #     ssh_public_key          = "ssh-rsa AAAAB3..."
  #     description             = "Development instance for data scientists"
  #   }
  # }
}

# -----------------------------------------------------------------------------
# PRIVATE ENDPOINT CONFIGURATION
# -----------------------------------------------------------------------------

variable "enable_private_endpoint" {
  description = "Create private endpoints"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Subnet ID for private endpoints"
  type        = string
  default     = null
}

variable "private_dns_zone_id_ml" {
  description = "Private DNS zone ID for ML workspace"
  type        = string
  default     = null
}

variable "private_dns_zone_id_storage" {
  description = "Private DNS zone ID for Storage Account"
  type        = string
  default     = null
}

variable "private_dns_zone_id_acr" {
  description = "Private DNS zone ID for Container Registry"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# MONITORING & DIAGNOSTICS
# -----------------------------------------------------------------------------

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostics"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# COST ALLOCATION
# -----------------------------------------------------------------------------

variable "cost_center" {
  description = "Cost center for billing"
  type        = string
  default     = "Machine-Learning"
}

variable "team" {
  description = "Team responsible for the resource"
  type        = string
  default     = "Data-Science"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}
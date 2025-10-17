# =============================================================================
# AZURE HDINSIGHT MODULE
# =============================================================================

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

locals {
  naming_prefix = "${var.customer_id}-${var.spoke_name}-${var.region_code}"
  hdinsight_cluster_name = coalesce(
    var.hdinsight_cluster_name,
    "hdi-${local.naming_prefix}"
  )
  storage_account_name = "hdist${replace(local.naming_prefix, "-", "")}${random_string.storage_suffix.result}"
  
  common_tags = merge(
    {
      Customer    = var.customer_id
      Environment = var.environment
      Spoke       = var.spoke_name
      Service     = "HDInsight"
      ManagedBy   = "Terraform"
      CostCenter  = var.cost_center
      Team        = var.team
    },
    var.tags
  )
}

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_password" "cluster_admin" {
  length  = 16
  special = true
}

resource "random_password" "ssh_password" {
  length  = 16
  special = true
}

# -----------------------------------------------------------------------------
# STORAGE ACCOUNT (Required for HDInsight)
# -----------------------------------------------------------------------------

resource "azurerm_storage_account" "hdinsight" {
  name                     = local.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.region
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true # Data Lake Gen2
  
  min_tls_version = "TLS1_2"
  
  tags = local.common_tags
}

resource "azurerm_storage_container" "hdinsight" {
  name                  = "hdinsight"
  storage_account_name  = azurerm_storage_account.hdinsight.name
  container_access_type = "private"
}

# -----------------------------------------------------------------------------
# HADOOP CLUSTER
# -----------------------------------------------------------------------------

resource "azurerm_hdinsight_hadoop_cluster" "main" {
  count = var.cluster_type == "Hadoop" ? 1 : 0
  
  name                = local.hdinsight_cluster_name
  resource_group_name = var.resource_group_name
  location            = var.region
  cluster_version     = var.cluster_version
  tier                = var.cluster_tier
  
  component_version {
    hadoop = var.hadoop_version
  }
  
  gateway {
    username = var.gateway_username
    password = var.gateway_password != null ? var.gateway_password : random_password.cluster_admin.result
  }
  
  storage_account {
    storage_container_id = azurerm_storage_container.hdinsight.id
    storage_account_key  = azurerm_storage_account.hdinsight.primary_access_key
    is_default           = true
  }
  
  roles {
    head_node {
      vm_size  = var.head_node_vm_size
      username = var.ssh_username
      password = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
    
    worker_node {
      vm_size               = var.worker_node_vm_size
      username              = var.ssh_username
      password              = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      target_instance_count = var.worker_node_count
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
    
    zookeeper_node {
      vm_size  = var.zookeeper_node_vm_size
      username = var.ssh_username
      password = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# SPARK CLUSTER
# -----------------------------------------------------------------------------

resource "azurerm_hdinsight_spark_cluster" "main" {
  count = var.cluster_type == "Spark" ? 1 : 0
  
  name                = local.hdinsight_cluster_name
  resource_group_name = var.resource_group_name
  location            = var.region
  cluster_version     = var.cluster_version
  tier                = var.cluster_tier
  
  component_version {
    spark = var.spark_version
  }
  
  gateway {
    username = var.gateway_username
    password = var.gateway_password != null ? var.gateway_password : random_password.cluster_admin.result
  }
  
  storage_account {
    storage_container_id = azurerm_storage_container.hdinsight.id
    storage_account_key  = azurerm_storage_account.hdinsight.primary_access_key
    is_default           = true
  }
  
  roles {
    head_node {
      vm_size  = var.head_node_vm_size
      username = var.ssh_username
      password = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
    
    worker_node {
      vm_size               = var.worker_node_vm_size
      username              = var.ssh_username
      password              = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      target_instance_count = var.worker_node_count
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
    
    zookeeper_node {
      vm_size  = var.zookeeper_node_vm_size
      username = var.ssh_username
      password = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# KAFKA CLUSTER
# -----------------------------------------------------------------------------

resource "azurerm_hdinsight_kafka_cluster" "main" {
  count = var.cluster_type == "Kafka" ? 1 : 0
  
  name                = local.hdinsight_cluster_name
  resource_group_name = var.resource_group_name
  location            = var.region
  cluster_version     = var.cluster_version
  tier                = var.cluster_tier
  
  component_version {
    kafka = var.kafka_version
  }
  
  gateway {
    username = var.gateway_username
    password = var.gateway_password != null ? var.gateway_password : random_password.cluster_admin.result
  }
  
  storage_account {
    storage_container_id = azurerm_storage_container.hdinsight.id
    storage_account_key  = azurerm_storage_account.hdinsight.primary_access_key
    is_default           = true
  }
  
  roles {
    head_node {
      vm_size  = var.head_node_vm_size
      username = var.ssh_username
      password = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
    
    worker_node {
      vm_size                  = var.worker_node_vm_size
      username                 = var.ssh_username
      password                 = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      target_instance_count    = var.worker_node_count
      number_of_disks_per_node = var.worker_node_disks_per_node
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
    
    zookeeper_node {
      vm_size  = var.zookeeper_node_vm_size
      username = var.ssh_username
      password = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# HBASE CLUSTER
# -----------------------------------------------------------------------------

resource "azurerm_hdinsight_hbase_cluster" "main" {
  count = var.cluster_type == "HBase" ? 1 : 0
  
  name                = local.hdinsight_cluster_name
  resource_group_name = var.resource_group_name
  location            = var.region
  cluster_version     = var.cluster_version
  tier                = var.cluster_tier
  
  component_version {
    hbase = var.hbase_version
  }
  
  gateway {
    username = var.gateway_username
    password = var.gateway_password != null ? var.gateway_password : random_password.cluster_admin.result
  }
  
  storage_account {
    storage_container_id = azurerm_storage_container.hdinsight.id
    storage_account_key  = azurerm_storage_account.hdinsight.primary_access_key
    is_default           = true
  }
  
  roles {
    head_node {
      vm_size  = var.head_node_vm_size
      username = var.ssh_username
      password = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
    
    worker_node {
      vm_size               = var.worker_node_vm_size
      username              = var.ssh_username
      password              = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      target_instance_count = var.worker_node_count
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
    
    zookeeper_node {
      vm_size  = var.zookeeper_node_vm_size
      username = var.ssh_username
      password = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
      
      dynamic "virtual_network_id" {
        for_each = var.subnet_id != null ? [1] : []
        content {
          virtual_network_id = var.vnet_id
          subnet_id          = var.subnet_id
        }
      }
    }
  }
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# STORE PASSWORDS IN KEY VAULT
# -----------------------------------------------------------------------------

resource "azurerm_key_vault_secret" "gateway_password" {
  count = var.key_vault_id != null ? 1 : 0
  
  name         = "${local.hdinsight_cluster_name}-gateway-password"
  value        = var.gateway_password != null ? var.gateway_password : random_password.cluster_admin.result
  key_vault_id = var.key_vault_id
  
  tags = local.common_tags
}

resource "azurerm_key_vault_secret" "ssh_password" {
  count = var.key_vault_id != null ? 1 : 0
  
  name         = "${local.hdinsight_cluster_name}-ssh-password"
  value        = var.ssh_password != null ? var.ssh_password : random_password.ssh_password.result
  key_vault_id = var.key_vault_id
  
  tags = local.common_tags
}

# -----------------------------------------------------------------------------
# DIAGNOSTIC SETTINGS
# -----------------------------------------------------------------------------

resource "azurerm_monitor_diagnostic_setting" "hdinsight" {
  count = var.log_analytics_workspace_id != null ? 1 : 0
  
  name               = "diag-${local.hdinsight_cluster_name}"
  target_resource_id = var.cluster_type == "Hadoop" ? azurerm_hdinsight_hadoop_cluster.main[0].id : (
    var.cluster_type == "Spark" ? azurerm_hdinsight_spark_cluster.main[0].id : (
      var.cluster_type == "Kafka" ? azurerm_hdinsight_kafka_cluster.main[0].id : 
      azurerm_hdinsight_hbase_cluster.main[0].id
    )
  )
  log_analytics_workspace_id = var.log_analytics_workspace_id
  
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
#!/usr/bin/env python3
"""
Generate terraform.tfvars from customer portal selections
Usage: python generate-tfvars.py --customer contoso --config config.json
"""

import json
import yaml
import argparse
from pathlib import Path
from typing import Dict, Any

def load_customer_config(customer_id: str) -> Dict[str, Any]:
    """Load customer configuration from portal/database"""
    config_path = Path(f"customers/{customer_id}/config.yaml")
    
    if not config_path.exists():
        raise FileNotFoundError(f"Customer config not found: {config_path}")
    
    with open(config_path, 'r') as f:
        return yaml.safe_load(f)

def generate_hub_tfvars(customer_id: str, config: Dict[str, Any]) -> str:
    """Generate Hub terraform.tfvars"""
    
    tfvars = f'''# Auto-generated terraform.tfvars for Hub
# Customer: {customer_id}
# Generated: {config.get('created_date', 'N/A')}

customer_id = "{customer_id}"
environment = "{config.get('environment', 'prd')}"
region      = "{config.get('region', 'eastus')}"
region_code = "{config.get('region_code', 'eus')}"

hub_vnet_cidr = "{config.get('hub_vnet_cidr', '10.0.0.0/16')}"

# Firewall
firewall_sku = "{config.get('firewall_sku', 'Standard')}"

# Optional components
enable_bastion     = {str(config.get('enable_bastion', True)).lower()}
enable_vpn_gateway = {str(config.get('enable_vpn_gateway', False)).lower()}

# Alerts
alert_email = "{config.get('email', 'ops@example.com')}"
'''
    
    return tfvars

def generate_management_tfvars(customer_id: str, config: Dict[str, Any]) -> str:
    """Generate Management terraform.tfvars"""
    
    emails = config.get('alert_emails', [config.get('email', 'ops@example.com')])
    emails_str = '["' + '", "'.join(emails) + '"]'
    
    tfvars = f'''# Auto-generated terraform.tfvars for Management
# Customer: {customer_id}

customer_id = "{customer_id}"
environment = "{config.get('environment', 'prd')}"
region      = "{config.get('region', 'eastus')}"
region_code = "{config.get('region_code', 'eus')}"

alert_emails = {emails_str}

monthly_budget = {config.get('monthly_budget', 0)}
'''
    
    return tfvars

def generate_spoke_tfvars(customer_id: str, config: Dict[str, Any], spoke_name: str) -> str:
    """Generate Spoke terraform.tfvars"""
    
    spoke_config = config.get('spokes', {}).get(spoke_name, {})
    
    tfvars = f'''# Auto-generated terraform.tfvars for Spoke: {spoke_name}
# Customer: {customer_id}

customer_id = "{customer_id}"
environment = "{config.get('environment', 'prd')}"
spoke_name  = "{spoke_name}"
region      = "{config.get('region', 'eastus')}"
region_code = "{config.get('region_code', 'eus')}"

spoke_vnet_cidr = "{spoke_config.get('vnet_cidr', '10.2.0.0/16')}"

# Service toggles (from portal selection)
enable_sql         = {str(spoke_config.get('services', {}).get('sql', {}).get('enabled', False)).lower()}
enable_keyvault    = {str(spoke_config.get('services', {}).get('keyvault', {}).get('enabled', False)).lower()}
enable_storage     = {str(spoke_config.get('services', {}).get('storage', {}).get('enabled', False)).lower()}
enable_datafactory = {str(spoke_config.get('services', {}).get('datafactory', {}).get('enabled', False)).lower()}

# SQL configuration
sql_database_name  = "{spoke_config.get('services', {}).get('sql', {}).get('database_name', 'app-db')}"
sql_admin_password = "REPLACE_WITH_KEYVAULT_SECRET"  # Set via Azure Key Vault
'''
    
    return tfvars

def main():
    parser = argparse.ArgumentParser(description='Generate Terraform tfvars from customer config')
    parser.add_argument('--customer', required=True, help='Customer ID')
    parser.add_argument('--component', default='all', choices=['all', 'hub', 'management', 'spoke'])
    parser.add_argument('--spoke', default='production', help='Spoke name')
    
    args = parser.parse_args()
    
    print(f"Generating tfvars for customer: {args.customer}")
    
    # Load customer config
    config = load_customer_config(args.customer)
    
    base_path = Path(f"terraform/environments/{args.customer}")
    
    # Generate Hub tfvars
    if args.component in ['all', 'hub']:
        hub_tfvars = generate_hub_tfvars(args.customer, config)
        hub_path = base_path / "hub" / "terraform.tfvars"
        hub_path.write_text(hub_tfvars)
        print(f"✓ Generated: {hub_path}")
    
    # Generate Management tfvars
    if args.component in ['all', 'management']:
        mgmt_tfvars = generate_management_tfvars(args.customer, config)
        mgmt_path = base_path / "management" / "terraform.tfvars"
        mgmt_path.write_text(mgmt_tfvars)
        print(f"✓ Generated: {mgmt_path}")
    
    # Generate Spoke tfvars
    if args.component in ['all', 'spoke']:
        spoke_tfvars = generate_spoke_tfvars(args.customer, config, args.spoke)
        spoke_path = base_path / "spokes" / args.spoke / "terraform.tfvars"
        spoke_path.write_text(spoke_tfvars)
        print(f"✓ Generated: {spoke_path}")
    
    print("\n✓ All tfvars generated successfully!")

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""
Generate Terraform tfvars from Excel parameter sheet
Usage: python generate-tfvars.py deployment-parameters.xlsx
"""

import pandas as pd
import json
import sys
from pathlib import Path
import ipaddress

class TerraformGenerator:
    def __init__(self, excel_file):
        self.excel_file = excel_file
        self.customer_info = None
        self.errors = []
        self.warnings = []
        
    def validate_cidr(self, cidr):
        """Validate CIDR notation"""
        try:
            ipaddress.ip_network(cidr, strict=False)
            return True
        except ValueError:
            return False
    
    def check_cidr_overlap(self, cidrs):
        """Check for overlapping CIDRs"""
        networks = [ipaddress.ip_network(c) for c in cidrs]
        for i, net1 in enumerate(networks):
            for net2 in networks[i+1:]:
                if net1.overlaps(net2):
                    return f"Overlap detected: {net1} and {net2}"
        return None
    
    def read_customer_info(self):
        """Read customer information tab"""
        df = pd.read_excel(self.excel_file, sheet_name='Customer-Info')
        self.customer_info = df.set_index('Parameter')['Value'].to_dict()
        
        # Validate required fields
        required = ['Customer ID', 'Environment', 'Primary Region', 'Region Code']
        for field in required:
            if not self.customer_info.get(field):
                self.errors.append(f"Missing required field: {field}")
    
    def generate_management_tfvars(self):
        """Generate Management tfvars"""
        df = pd.read_excel(self.excel_file, sheet_name='Management')
        
        tfvars = {
            'customer_id': self.customer_info['Customer ID'],
            'environment': self.customer_info['Environment'],
            'region': self.customer_info['Primary Region'],
            'region_code': self.customer_info['Region Code'],
        }
        
        # Add component-specific values
        for _, row in df.iterrows():
            if pd.notna(row['Value']) and row['Value'] != '':
                key = row['Parameter'].lower().replace(' ', '_')
                tfvars[key] = row['Value']
        
        return tfvars
    
    def generate_hub_tfvars(self):
        """Generate Hub tfvars"""
        df = pd.read_excel(self.excel_file, sheet_name='Hub')
        
        tfvars = {
            'customer_id': self.customer_info['Customer ID'],
            'environment': self.customer_info['Environment'],
            'region': self.customer_info['Primary Region'],
            'region_code': self.customer_info['Region Code'],
        }
        
        # Extract VNet CIDR
        hub_cidr = df[df['Parameter'] == 'CIDR']['Value'].values[0]
        if not self.validate_cidr(hub_cidr):
            self.errors.append(f"Invalid Hub CIDR: {hub_cidr}")
        
        tfvars['hub_vnet_cidr'] = hub_cidr
        
        # Firewall settings
        tfvars['firewall_sku'] = df[df['Parameter'] == 'SKU']['Value'].values[0]
        tfvars['enable_bastion'] = df[df['Parameter'] == 'Enable']['Value'].values[0] == 'Yes'
        
        return tfvars
    
    def generate_spoke_tfvars(self, spoke_name):
        """Generate Spoke tfvars"""
        df = pd.read_excel(self.excel_file, sheet_name=f'Spoke-{spoke_name}')
        
        tfvars = {
            'customer_id': self.customer_info['Customer ID'],
            'environment': self.customer_info['Environment'],
            'spoke_name': spoke_name,
            'region': self.customer_info['Primary Region'],
            'region_code': self.customer_info['Region Code'],
        }
        
        # Extract spoke CIDR
        spoke_cidr = df[df['Parameter'] == 'VNet CIDR']['Value'].values[0]
        if not self.validate_cidr(spoke_cidr):
            self.errors.append(f"Invalid Spoke CIDR: {spoke_cidr}")
        
        tfvars['spoke_vnet_cidr'] = spoke_cidr
        
        # Service enablement
        services = df[df['Component'] == 'Services']
        tfvars['enable_keyvault'] = services[services['Parameter'] == 'Key Vault']['Value'].values[0] == 'Yes'
        tfvars['enable_sql'] = services[services['Parameter'] == 'SQL Database']['Value'].values[0] == 'Yes'
        tfvars['enable_storage'] = services[services['Parameter'] == 'Storage/Data Lake']['Value'].values[0] == 'Yes'
        tfvars['enable_datafactory'] = services[services['Parameter'] == 'Data Factory']['Value'].values[0] == 'Yes'
        
        return tfvars
    
    def write_tfvars(self, tfvars, output_file):
        """Write tfvars to file"""
        with open(output_file, 'w') as f:
            for key, value in tfvars.items():
                if isinstance(value, str):
                    f.write(f'{key} = "{value}"\n')
                elif isinstance(value, bool):
                    f.write(f'{key} = {str(value).lower()}\n')
                else:
                    f.write(f'{key} = {value}\n')
    
    def generate_all(self):
        """Generate all tfvars files"""
        print("🚀 Terraform Variables Generator")
        print("=" * 50)
        
        # Read customer info
        self.read_customer_info()
        
        if self.errors:
            print("\n❌ ERRORS:")
            for error in self.errors:
                print(f"  - {error}")
            return False
        
        customer_id = self.customer_info['Customer ID']
        
        # Generate Management
        print("\n📊 Generating Management tfvars...")
        mgmt_tfvars = self.generate_management_tfvars()
        mgmt_path = f"terraform/environments/{customer_id}/management/terraform.tfvars"
        Path(mgmt_path).parent.mkdir(parents=True, exist_ok=True)
        self.write_tfvars(mgmt_tfvars, mgmt_path)
        print(f"  ✅ Created: {mgmt_path}")
        
        # Generate Hub
        print("\n🌐 Generating Hub tfvars...")
        hub_tfvars = self.generate_hub_tfvars()
        hub_path = f"terraform/environments/{customer_id}/hub/terraform.tfvars"
        Path(hub_path).parent.mkdir(parents=True, exist_ok=True)
        self.write_tfvars(hub_tfvars, hub_path)
        print(f"  ✅ Created: {hub_path}")
        
        # Generate Spokes
        print("\n📦 Generating Spoke tfvars...")
        spoke_sheets = [s for s in pd.ExcelFile(self.excel_file).sheet_names if s.startswith('Spoke-')]
        for sheet in spoke_sheets:
            spoke_name = sheet.replace('Spoke-', '')
            spoke_tfvars = self.generate_spoke_tfvars(spoke_name)
            spoke_path = f"terraform/environments/{customer_id}/spokes/{spoke_name}/terraform.tfvars"
            Path(spoke_path).parent.mkdir(parents=True, exist_ok=True)
            self.write_tfvars(spoke_tfvars, spoke_path)
            print(f"  ✅ Created: {spoke_path}")
        
        print("\n✅ Generation complete!")
        return True

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python generate-tfvars.py <excel-file>")
        sys.exit(1)
    
    generator = TerraformGenerator(sys.argv[1])
    success = generator.generate_all()
    sys.exit(0 if success else 1)
"""
Terraform Execution Utility
Wrapper for running Terraform commands
"""

import subprocess
import json
import os
from typing import Dict, Any, Optional
from pathlib import Path
import logging

from config import settings
from models.customer import Customer

logger = logging.getLogger(__name__)

class TerraformRunner:
    """
    Execute Terraform commands for customer deployments
    """
    
    def __init__(self, customer_id: str, component: str, customer: Customer):
        self.customer_id = customer_id
        self.component = component
        self.customer = customer
        
        # Set working directory
        self.working_dir = Path(settings.TF_ENVIRONMENTS_PATH) / customer_id / component
        
        if not self.working_dir.exists():
            raise FileNotFoundError(f"Terraform directory not found: {self.working_dir}")
        
        # Set environment variables for Azure authentication
        self.env = os.environ.copy()
        self.env.update({
            "ARM_TENANT_ID": customer.tenant_id,
            "ARM_SUBSCRIPTION_ID": self._get_subscription_id(component),
            "ARM_CLIENT_ID": customer.sp_client_id,
            "ARM_CLIENT_SECRET": self._decrypt_secret(customer.sp_client_secret),
            "TF_IN_AUTOMATION": "1"
        })
    
    def _get_subscription_id(self, component: str) -> str:
        """Get subscription ID for component"""
        if component == "hub":
            return self.customer.subscription_ids.get("hub")
        elif component == "management":
            return self.customer.subscription_ids.get("management")
        elif component.startswith("spoke-"):
            spoke_name = component.replace("spoke-", "")
            return self.customer.subscription_ids.get("spokes", {}).get(spoke_name)
        
        raise ValueError(f"Unknown component: {component}")
    
    def _decrypt_secret(self, encrypted_secret: str) -> str:
        """Decrypt service principal secret"""
        # TODO: Implement actual decryption
        from ..utils.encryption import decrypt_value
        return decrypt_value(encrypted_secret)
    
    def _run_command(self, command: list, capture_output: bool = True) -> Dict[str, Any]:
        """Execute Terraform command"""
        logger.info(f"Running: {' '.join(command)} in {self.working_dir}")
        
        try:
            result = subprocess.run(
                command,
                cwd=self.working_dir,
                env=self.env,
                capture_output=capture_output,
                text=True,
                timeout=3600  # 1 hour timeout
            )
            
            return {
                "success": result.returncode == 0,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "returncode": result.returncode
            }
        
        except subprocess.TimeoutExpired:
            logger.error(f"Terraform command timed out: {command}")
            raise Exception("Terraform execution timed out (1 hour)")
        
        except Exception as e:
            logger.error(f"Terraform command failed: {e}", exc_info=True)
            raise
    
    def init(self) -> Dict[str, Any]:
        """Run terraform init"""
        result = self._run_command(["terraform", "init", "-upgrade"])
        
        if not result["success"]:
            raise Exception(f"Terraform init failed: {result['stderr']}")
        
        return result
    
    def validate(self) -> Dict[str, Any]:
        """Run terraform validate"""
        result = self._run_command(["terraform", "validate"])
        
        if not result["success"]:
            raise Exception(f"Terraform validate failed: {result['stderr']}")
        
        return result
    
    def plan(self) -> Dict[str, Any]:
        """Run terraform plan"""
        self.init()
        self.validate()
        
        result = self._run_command([
            "terraform", "plan",
            "-out=tfplan",
            "-detailed-exitcode"
        ])
        
        # Exit code 0 = no changes, 1 = error, 2 = changes present
        has_changes = result["returncode"] == 2
        
        return {
            "success": result["returncode"] in [0, 2],
            "has_changes": has_changes,
            "plan_output": result["stdout"],
            "error": result["stderr"] if result["returncode"] == 1 else None
        }
    
    def apply(self) -> Dict[str, Any]:
        """Run terraform apply"""
        result = self._run_command([
            "terraform", "apply",
            "-auto-approve",
            "tfplan"
        ])
        
        if not result["success"]:
            raise Exception(f"Terraform apply failed: {result['stderr']}")
        
        # Get outputs
        outputs = self.output()
        
        # Parse resources from output
        resources = self._parse_resources(result["stdout"])
        
        return {
            "success": True,
            "output": result["stdout"],
            "terraform_outputs": outputs,
            "resources": resources
        }
    
    def destroy(self) -> Dict[str, Any]:
        """Run terraform destroy"""
        self.init()
        
        result = self._run_command([
            "terraform", "destroy",
            "-auto-approve"
        ])
        
        if not result["success"]:
            raise Exception(f"Terraform destroy failed: {result['stderr']}")
        
        return {
            "success": True,
            "output": result["stdout"]
        }
    
    def output(self) -> Dict[str, Any]:
        """Get terraform outputs"""
        result = self._run_command(["terraform", "output", "-json"])
        
        if result["success"]:
            return json.loads(result["stdout"])
        
        return {}
    
    def _parse_resources(self, terraform_output: str) -> Dict[str, Any]:
        """Parse created resources from Terraform output"""
        resources = {
            "resource_groups": [],
            "vnets": [],
            "subnets": [],
            "nsgs": [],
            "count": 0
        }
        
        # Simple parsing (improve with regex)
        lines = terraform_output.split("\n")
        for line in lines:
            if "azurerm_resource_group" in line and "created" in line.lower():
                resources["resource_groups"].append(line.strip())
                resources["count"] += 1
            elif "azurerm_virtual_network" in line and "created" in line.lower():
                resources["vnets"].append(line.strip())
                resources["count"] += 1
        
        return resources
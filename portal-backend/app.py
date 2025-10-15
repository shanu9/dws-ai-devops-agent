from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import requests
from datetime import datetime
from typing import Optional

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Config from environment
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
GITHUB_REPO = os.getenv("GITHUB_REPO")  # e.g., "username/azure-caflz-saas"

# In-memory storage (replace with database later)
deployments = {}

class DeployRequest(BaseModel):
    packageType: str
    companyName: str
    contactEmail: str
    azureSubscriptions: dict
    networkConfig: dict

def generate_customer_id(company_name: str) -> str:
    """Generate customer ID from company name"""
    return company_name.lower().replace(' ', '').replace('-', '')[:6]

def trigger_github_workflow(customer_id: str, request: DeployRequest):
    """Trigger GitHub Actions deployment workflow"""
    headers = {
        "Authorization": f"Bearer {GITHUB_TOKEN}",
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28"
    }
    
    url = f"https://api.github.com/repos/{GITHUB_REPO}/actions/workflows/deploy-infrastructure.yml/dispatches"
    
    payload = {
        "ref": "main",
        "inputs": {
            "customer_id": customer_id,
            "customer_name": request.companyName,
            "customer_email": request.contactEmail,
            "region": "eastus",
            "package_tier": request.packageType,
            "hub_vnet_cidr": request.networkConfig.get('hubVnetCidr', '10.1.0.0/16'),
            "spoke_vnet_cidr": request.networkConfig.get('spokeVnetCidr', '10.2.0.0/16')
        }
    }
    
    response = requests.post(url, json=payload, headers=headers)
    
    if response.status_code != 204:
        raise Exception(f"GitHub API error: {response.status_code} - {response.text}")
    
    return True

@app.post("/api/deploy")
async def deploy_infrastructure(request: DeployRequest):
    """Main deployment endpoint"""
    try:
        # Generate customer ID
        customer_id = generate_customer_id(request.companyName)
        
        # Store deployment info
        deployments[customer_id] = {
            "id": customer_id,
            "customer_name": request.companyName,
            "email": request.contactEmail,
            "package": request.packageType,
            "status": "queued",
            "progress": 0,
            "current_step": "Queued",
            "created_at": datetime.now().isoformat(),
            "github_url": f"https://github.com/{GITHUB_REPO}/actions"
        }
        
        # Trigger GitHub Actions
        trigger_github_workflow(customer_id, request)
        
        return {
            "success": True,
            "deploymentId": customer_id,
            "message": "Deployment started successfully",
            "githubUrl": f"https://github.com/{GITHUB_REPO}/actions"
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/deployments/{deployment_id}")
async def get_deployment_status(deployment_id: str):
    """Get deployment status"""
    deployment = deployments.get(deployment_id)
    
    if not deployment:
        raise HTTPException(status_code=404, detail="Deployment not found")
    
    return deployment

@app.get("/api/deployments")
async def list_deployments():
    """List all deployments"""
    return list(deployments.values())

@app.post("/api/webhook/github")
async def github_webhook(payload: dict):
    """Webhook to receive GitHub Actions updates"""
    customer_id = payload.get("customer_id")
    status = payload.get("status")
    step = payload.get("step", "")
    
    if customer_id in deployments:
        deployments[customer_id]["status"] = status
        deployments[customer_id]["current_step"] = step
        
        # Update progress based on step
        progress_map = {
            "validate": 10,
            "management": 30,
            "hub": 60,
            "spoke": 90,
            "completed": 100
        }
        deployments[customer_id]["progress"] = progress_map.get(step.lower(), 0)
    
    return {"success": True}

@app.get("/api/packages")
async def get_packages():
    """Get available packages"""
    return [
        {
            "id": "basic",
            "name": "Basic",
            "price": 1500,
            "features": ["Management", "Hub", "1 Spoke", "Key Vault"]
        },
        {
            "id": "standard",
            "name": "Standard",
            "price": 3500,
            "features": ["Management", "Hub", "1 Spoke", "SQL", "Storage", "Key Vault"]
        },
        {
            "id": "premium",
            "name": "Premium",
            "price": 6500,
            "features": ["Management", "Hub", "2 Spokes", "SQL", "Storage", "Key Vault", "VPN Gateway", "Premium Firewall"]
        }
    ]

@app.get("/")
async def root():
    return {"status": "Azure CAF-LZ Portal API", "version": "1.0"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
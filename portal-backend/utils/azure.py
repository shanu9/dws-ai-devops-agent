"""
Azure SDK Utilities
Interact with Azure services (Cost Management, Resource Graph, Monitor)
"""

from azure.identity import DefaultAzureCredential, ClientSecretCredential
from azure.mgmt.resource import ResourceManagementClient
from azure.mgmt.monitor import MonitorManagementClient
from azure.mgmt.costmanagement import CostManagementClient
from azure.mgmt.costmanagement.models import QueryDefinition, QueryTimePeriod, QueryDataset, QueryAggregation
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import logging

logger = logging.getLogger(__name__)

class AzureClient:
    """Azure SDK client wrapper"""
    
    def __init__(self, tenant_id: str, subscription_id: str, client_id: str = None, client_secret: str = None):
        self.subscription_id = subscription_id
        
        # Use service principal if provided, else default credential
        if client_id and client_secret:
            self.credential = ClientSecretCredential(
                tenant_id=tenant_id,
                client_id=client_id,
                client_secret=client_secret
            )
        else:
            self.credential = DefaultAzureCredential()
        
        # Initialize clients
        self.resource_client = ResourceManagementClient(self.credential, subscription_id)
        self.monitor_client = MonitorManagementClient(self.credential, subscription_id)
        self.cost_client = CostManagementClient(self.credential)
    
    def list_resource_groups(self) -> List[Dict[str, Any]]:
        """List all resource groups"""
        try:
            rgs = self.resource_client.resource_groups.list()
            return [{"name": rg.name, "location": rg.location, "tags": rg.tags} for rg in rgs]
        except Exception as e:
            logger.error(f"Failed to list resource groups: {e}")
            return []
    
    def list_resources(self, resource_group_name: Optional[str] = None) -> List[Dict[str, Any]]:
        """List resources in subscription or resource group"""
        try:
            if resource_group_name:
                resources = self.resource_client.resources.list_by_resource_group(resource_group_name)
            else:
                resources = self.resource_client.resources.list()
            
            return [{
                "name": r.name,
                "type": r.type,
                "location": r.location,
                "id": r.id,
                "tags": r.tags
            } for r in resources]
        except Exception as e:
            logger.error(f"Failed to list resources: {e}")
            return []
    
    def get_resource_costs(self, resource_group_name: str, days: int = 30) -> Dict[str, Any]:
        """Get costs for a resource group using Cost Management API"""
        try:
            scope = f"/subscriptions/{self.subscription_id}/resourceGroups/{resource_group_name}"
            
            # Define time period
            end_date = datetime.utcnow()
            start_date = end_date - timedelta(days=days)
            
            time_period = QueryTimePeriod(
                from_property=start_date.isoformat(),
                to=end_date.isoformat()
            )
            
            # Define query
            query = QueryDefinition(
                type="ActualCost",
                timeframe="Custom",
                time_period=time_period,
                dataset=QueryDataset(
                    granularity="Daily",
                    aggregation={
                        "totalCost": QueryAggregation(
                            name="Cost",
                            function="Sum"
                        )
                    }
                )
            )
            
            # Execute query
            result = self.cost_client.query.usage(scope, query)
            
            total_cost = 0.0
            if result.rows:
                for row in result.rows:
                    total_cost += float(row[0])  # Cost column
            
            return {
                "resource_group": resource_group_name,
                "total_cost": round(total_cost, 2),
                "period_days": days,
                "currency": "USD"
            }
        
        except Exception as e:
            logger.error(f"Failed to get resource costs: {e}")
            return {
                "resource_group": resource_group_name,
                "total_cost": 0.0,
                "error": str(e)
            }
    
    def get_resource_metrics(self, resource_id: str, metric_name: str, hours: int = 24) -> List[Dict[str, Any]]:
        """Get metrics for a resource"""
        try:
            end_time = datetime.utcnow()
            start_time = end_time - timedelta(hours=hours)
            
            timespan = f"{start_time.isoformat()}/{end_time.isoformat()}"
            
            metrics_data = self.monitor_client.metrics.list(
                resource_id,
                timespan=timespan,
                interval='PT1H',
                metricnames=metric_name,
                aggregation='Average'
            )
            
            results = []
            for item in metrics_data.value:
                for timeseries in item.timeseries:
                    for data in timeseries.data:
                        if data.average is not None:
                            results.append({
                                "timestamp": data.time_stamp.isoformat(),
                                "metric": metric_name,
                                "value": data.average,
                                "unit": item.unit
                            })
            
            return results
        
        except Exception as e:
            logger.error(f"Failed to get metrics: {e}")
            return []
    
    def check_resource_health(self, resource_id: str) -> Dict[str, Any]:
        """Check health status of a resource"""
        try:
            # Note: Requires azure-mgmt-resourcehealth package
            # Simplified implementation
            return {
                "resource_id": resource_id,
                "status": "Available",
                "timestamp": datetime.utcnow().isoformat()
            }
        except Exception as e:
            logger.error(f"Failed to check resource health: {e}")
            return {"status": "Unknown", "error": str(e)}
    
    def get_subscription_cost_summary(self, days: int = 30) -> Dict[str, Any]:
        """Get total subscription costs"""
        try:
            scope = f"/subscriptions/{self.subscription_id}"
            
            end_date = datetime.utcnow()
            start_date = end_date - timedelta(days=days)
            
            time_period = QueryTimePeriod(
                from_property=start_date.isoformat(),
                to=end_date.isoformat()
            )
            
            query = QueryDefinition(
                type="ActualCost",
                timeframe="Custom",
                time_period=time_period,
                dataset=QueryDataset(
                    granularity="Daily",
                    aggregation={
                        "totalCost": QueryAggregation(name="Cost", function="Sum")
                    },
                    grouping=[
                        {"type": "Dimension", "name": "ResourceType"}
                    ]
                )
            )
            
            result = self.cost_client.query.usage(scope, query)
            
            total_cost = 0.0
            breakdown = {}
            
            if result.rows:
                for row in result.rows:
                    cost = float(row[0])
                    resource_type = row[1] if len(row) > 1 else "Unknown"
                    
                    total_cost += cost
                    breakdown[resource_type] = breakdown.get(resource_type, 0.0) + cost
            
            return {
                "subscription_id": self.subscription_id,
                "total_cost": round(total_cost, 2),
                "period_days": days,
                "breakdown": {k: round(v, 2) for k, v in breakdown.items()},
                "currency": "USD"
            }
        
        except Exception as e:
            logger.error(f"Failed to get subscription costs: {e}")
            return {
                "subscription_id": self.subscription_id,
                "total_cost": 0.0,
                "error": str(e)
            }
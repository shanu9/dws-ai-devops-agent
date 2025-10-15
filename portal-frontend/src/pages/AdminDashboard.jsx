import React, { useState, useEffect } from 'react';
import { 
  Github, 
  Cloud, 
  Activity, 
  DollarSign, 
  Server, 
  CheckCircle2, 
  XCircle, 
  Clock,
  AlertCircle,
  RefreshCw,
  ExternalLink,
  Terminal,
  Database,
  Zap,
  TrendingUp
} from 'lucide-react';
import Navigation from '../components/Navigation';
import CostWidget from '../components/CostWidget';
import CostBreakdown from '../components/CostBreakdown';
import SavingsRecommendations from '../components/SavingsRecommendations';

const AdminDashboard = () => {
  const [deployments, setDeployments] = useState([]);
  const [githubWorkflows, setGithubWorkflows] = useState([]);
  const [azureResources, setAzureResources] = useState([]);
  const [costs, setCosts] = useState({ daily: 0, monthly: 0 });
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchAllData();
    const interval = setInterval(fetchAllData, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchAllData = async () => {
    try {
      const deploymentsRes = await fetch('http://localhost:8000/api/deployments');
      if (deploymentsRes.ok) {
        const deploymentsData = await deploymentsRes.json();
        setDeployments(deploymentsData);
      }

      setGithubWorkflows([
        { id: 1, name: 'Deploy Infrastructure', status: 'success', started_at: new Date(Date.now() - 3600000).toISOString(), duration: '45m 23s', customer: 'custm1' },
        { id: 2, name: 'Deploy Infrastructure', status: 'in_progress', started_at: new Date(Date.now() - 1800000).toISOString(), duration: '18m 12s', customer: 'demo01' }
      ]);

      setAzureResources([
        { type: 'Virtual Network', count: 2, status: 'healthy' },
        { type: 'Firewall', count: 1, status: 'healthy' },
        { type: 'Log Analytics', count: 3, status: 'healthy' },
        { type: 'Key Vault', count: 1, status: 'healthy' },
        { type: 'SQL Database', count: 1, status: 'degraded' }
      ]);

      setCosts({ daily: 115.50, monthly: 3465.00 });
      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch data:', error);
      setLoading(false);
    }
  };

  const getStatusColor = (status) => {
    const colors = {
      success: 'text-green-600 bg-green-100',
      completed: 'text-green-600 bg-green-100',
      in_progress: 'text-blue-600 bg-blue-100',
      pending: 'text-yellow-600 bg-yellow-100',
      failed: 'text-red-600 bg-red-100',
      error: 'text-red-600 bg-red-100',
      healthy: 'text-green-600',
      degraded: 'text-yellow-600',
      unhealthy: 'text-red-600'
    };
    return colors[status] || 'text-gray-600 bg-gray-100';
  };

  const getStatusIcon = (status) => {
    if (status === 'success' || status === 'completed' || status === 'healthy') {
      return <CheckCircle2 className="w-5 h-5" />;
    } else if (status === 'in_progress' || status === 'pending') {
      return <Clock className="w-5 h-5 animate-spin" />;
    } else if (status === 'failed' || status === 'error' || status === 'unhealthy') {
      return <XCircle className="w-5 h-5" />;
    }
    return <AlertCircle className="w-5 h-5" />;
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <RefreshCw className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <>
      <Navigation currentPage="admin" />
      
      <div className="min-h-screen bg-gray-50">
        <div className="bg-white border-b border-gray-200">
          <div className="max-w-7xl mx-auto px-4 py-6">
            <div className="flex items-center justify-between">
              <div>
                <h1 className="text-3xl font-bold text-gray-900">Admin DevOps Dashboard</h1>
                <p className="text-gray-600 mt-1">Monitor all deployments, resources, and costs in real-time</p>
              </div>
              <button onClick={fetchAllData} className="flex items-center space-x-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors">
                <RefreshCw className="w-4 h-4" />
                <span>Refresh</span>
              </button>
            </div>
          </div>
        </div>

        <div className="max-w-7xl mx-auto px-4 py-8">
          <div className="grid grid-cols-4 gap-6 mb-8">
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <Github className="w-8 h-8 text-gray-700" />
                <span className="text-sm text-green-600 font-semibold">2 Active</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">{githubWorkflows.length}</div>
              <div className="text-sm text-gray-600">GitHub Workflows</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <Server className="w-8 h-8 text-blue-600" />
                <span className="text-sm text-blue-600 font-semibold">All Healthy</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">{azureResources.reduce((sum, r) => sum + r.count, 0)}</div>
              <div className="text-sm text-gray-600">Azure Resources</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <Activity className="w-8 h-8 text-green-600" />
                <span className="text-sm text-green-600 font-semibold">↑ 15%</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">{deployments.length}</div>
              <div className="text-sm text-gray-600">Total Deployments</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <DollarSign className="w-8 h-8 text-yellow-600" />
                <span className="text-sm text-red-600 font-semibold">↑ 8%</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">${costs.daily.toFixed(2)}</div>
              <div className="text-sm text-gray-600">Daily Cost</div>
            </div>
          </div>

          <div className="mb-8">
            <h2 className="text-2xl font-bold text-gray-900 mb-4">Platform Cost Analytics</h2>
            <CostWidget />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            <CostBreakdown />
            <SavingsRecommendations />
          </div>

          <div className="grid grid-cols-2 gap-6 mb-6">
            <div className="bg-white rounded-xl shadow-sm border border-gray-200">
              <div className="p-6 border-b border-gray-200">
                <div className="flex items-center justify-between">
                  <h2 className="text-xl font-bold text-gray-900 flex items-center">
                    <Github className="w-6 h-6 mr-2" />
                    GitHub Actions
                  </h2>
                  <a href="https://github.com" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:text-blue-700 flex items-center text-sm">
                    View in GitHub
                    <ExternalLink className="w-4 h-4 ml-1" />
                  </a>
                </div>
              </div>
              <div className="p-6 space-y-4">
                {githubWorkflows.map((workflow) => (
                  <div key={workflow.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors cursor-pointer">
                    <div className="flex items-center space-x-4">
                      <div className={`p-2 rounded-lg ${getStatusColor(workflow.status)}`}>
                        {getStatusIcon(workflow.status)}
                      </div>
                      <div>
                        <div className="font-semibold text-gray-900">{workflow.name}</div>
                        <div className="text-sm text-gray-600">Customer: {workflow.customer}</div>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-medium text-gray-900">{workflow.duration}</div>
                      <div className="text-xs text-gray-500">{new Date(workflow.started_at).toLocaleTimeString()}</div>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-white rounded-xl shadow-sm border border-gray-200">
              <div className="p-6 border-b border-gray-200">
                <div className="flex items-center justify-between">
                  <h2 className="text-xl font-bold text-gray-900 flex items-center">
                    <Cloud className="w-6 h-6 mr-2" />
                    Azure Resources
                  </h2>
                  <a href="https://portal.azure.com" target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:text-blue-700 flex items-center text-sm">
                    Open Portal
                    <ExternalLink className="w-4 h-4 ml-1" />
                  </a>
                </div>
              </div>
              <div className="p-6 space-y-3">
                {azureResources.map((resource, index) => (
                  <div key={index} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
                    <div className="flex items-center space-x-3">
                      <Server className="w-5 h-5 text-gray-600" />
                      <div>
                        <div className="font-medium text-gray-900">{resource.type}</div>
                        <div className="text-sm text-gray-600">{resource.count} instance{resource.count > 1 ? 's' : ''}</div>
                      </div>
                    </div>
                    <div className={`flex items-center space-x-2 ${getStatusColor(resource.status)}`}>
                      {getStatusIcon(resource.status)}
                      <span className="text-sm font-medium capitalize">{resource.status}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="bg-white rounded-xl shadow-sm border border-gray-200 mb-6">
            <div className="p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900 flex items-center">
                <Terminal className="w-6 h-6 mr-2" />
                Recent Deployments
              </h2>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Customer</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Package</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Started</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Cost</th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {deployments.map((deployment) => (
                    <tr key={deployment.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="font-medium text-gray-900">{deployment.customer_name || 'Unknown'}</div>
                        <div className="text-sm text-gray-500">{deployment.customer_id}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span className="px-2 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-800 capitalize">{deployment.package_tier}</span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className={`inline-flex items-center space-x-2 px-3 py-1 rounded-full ${getStatusColor(deployment.status)}`}>
                          {getStatusIcon(deployment.status)}
                          <span className="text-sm font-medium capitalize">{deployment.status}</span>
                        </div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">{new Date(deployment.started_at).toLocaleString()}</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">${deployment.estimated_monthly_cost || 0}/mo</td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm">
                        {deployment.github_run_url && (
                          <a href={deployment.github_run_url} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:text-blue-700 flex items-center">
                            View Logs
                            <ExternalLink className="w-4 h-4 ml-1" />
                          </a>
                        )}
                      </td>
                    </tr>
                  ))}
                  {deployments.length === 0 && (
                    <tr>
                      <td colSpan="6" className="px-6 py-12 text-center text-gray-500">
                        No deployments yet. Deploy your first infrastructure!
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-6">
            <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-6 text-white">
              <div className="flex items-center justify-between mb-4">
                <DollarSign className="w-8 h-8" />
                <Zap className="w-6 h-6 opacity-75" />
              </div>
              <div className="text-3xl font-bold mb-2">${costs.monthly.toFixed(2)}</div>
              <div className="text-blue-100">Projected Monthly Cost</div>
            </div>

            <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-xl p-6 text-white">
              <div className="flex items-center justify-between mb-4">
                <Database className="w-8 h-8" />
                <CheckCircle2 className="w-6 h-6 opacity-75" />
              </div>
              <div className="text-3xl font-bold mb-2">{azureResources.reduce((sum, r) => sum + r.count, 0)}</div>
              <div className="text-green-100">Active Resources</div>
            </div>

            <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-6 text-white">
              <div className="flex items-center justify-between mb-4">
                <Activity className="w-8 h-8" />
                <TrendingUp className="w-6 h-6 opacity-75" />
              </div>
              <div className="text-3xl font-bold mb-2">99.9%</div>
              <div className="text-purple-100">Platform Uptime</div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default AdminDashboard;
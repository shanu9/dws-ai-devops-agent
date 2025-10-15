import React, { useState, useEffect } from 'react';
import { 
  Cloud, 
  Activity, 
  DollarSign, 
  Server, 
  CheckCircle2, 
  Square, 
  RefreshCw,
  ExternalLink,
  Database,
  Zap,
  TrendingUp,
  AlertCircle,
  FileText
} from 'lucide-react';
import Navigation from '../components/Navigation';
import CostWidget from '../components/CostWidget';
import CostBreakdown from '../components/CostBreakdown';
import SavingsRecommendations from '../components/SavingsRecommendations';
import LoadingSkeleton from '../components/LoadingSkeleton';
import EmptyState from '../components/EmptyState';
import Tooltip from '../components/Tooltip';
import { ToastContainer, useToast } from '../components/Toast';

const CustomerDashboard = () => {
  const [currentCustomer] = useState({
    id: 'custm1',
    name: 'shanu',
    package: 'standard'
  });

  const [myDeployments, setMyDeployments] = useState([]);
  const [myResources, setMyResources] = useState([]);
  const [myCosts, setMyCosts] = useState({ daily: 0, monthly: 0, thisMonth: 0 });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const { toasts, addToast, removeToast } = useToast();

  useEffect(() => {
    fetchMyData();
    const interval = setInterval(fetchMyData, 30000);
    return () => clearInterval(interval);
  }, []);

  const fetchMyData = async () => {
    try {
      setError(null);
      const deploymentsRes = await fetch('http://localhost:8000/api/deployments');
      
      if (!deploymentsRes.ok) {
        throw new Error('Failed to fetch deployments');
      }
      
      const allDeployments = await deploymentsRes.json();
      const filtered = allDeployments.filter(d => d.customer_id === currentCustomer.id);
      setMyDeployments(filtered);

      setMyResources([
        { name: 'Hub VNet', type: 'Virtual Network', status: 'running', region: 'East US', cost: 15.50 },
        { name: 'Production Spoke', type: 'Virtual Network', status: 'running', region: 'East US', cost: 12.30 },
        { name: 'Azure Firewall', type: 'Firewall', status: 'running', region: 'East US', cost: 48.00 },
        { name: 'Central Logs', type: 'Log Analytics', status: 'running', region: 'East US', cost: 8.20 },
        { name: 'Production KV', type: 'Key Vault', status: 'running', region: 'East US', cost: 2.50 }
      ]);

      setMyCosts({ daily: 86.50, monthly: 2595.00, thisMonth: 1847.32 });
      setLoading(false);
      
      if (loading) {
        addToast('Dashboard data refreshed successfully', 'success');
      }
    } catch (error) {
      console.error('Failed to fetch data:', error);
      setError(error.message);
      setLoading(false);
      addToast('Failed to load dashboard data', 'error');
    }
  };

  const handleRefresh = () => {
    setLoading(true);
    fetchMyData();
  };

  const getStatusColor = (status) => {
    const colors = {
      running: 'text-green-600 bg-green-100',
      stopped: 'text-gray-600 bg-gray-100',
      error: 'text-red-600 bg-red-100'
    };
    return colors[status] || 'text-gray-600 bg-gray-100';
  };

  const getStatusIcon = (status) => {
    if (status === 'running') return <CheckCircle2 className="w-5 h-5" />;
    if (status === 'stopped') return <Square className="w-5 h-5" />;
    return <AlertCircle className="w-5 h-5" />;
  };

  if (loading && !myResources.length) {
    return (
      <>
        <Navigation currentPage="customer" />
        <LoadingSkeleton type="page" />
      </>
    );
  }

  if (error && !myResources.length) {
    return (
      <>
        <Navigation currentPage="customer" />
        <div className="min-h-screen bg-gray-50 flex items-center justify-center">
          <EmptyState 
            type="error"
            description={error}
            actionLabel="Retry"
            onAction={fetchMyData}
          />
        </div>
      </>
    );
  }

  return (
    <>
      <Navigation currentPage="customer" />
      <ToastContainer toasts={toasts} removeToast={removeToast} />
      
      <div className="min-h-screen bg-gray-50">
        {/* Customer Header */}
        <div className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white">
          <div className="max-w-7xl mx-auto px-4 py-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <Cloud className="w-8 h-8" />
                <div>
                  <h1 className="text-3xl font-bold">My Infrastructure</h1>
                  <p className="text-blue-100 mt-1">Welcome back, {currentCustomer.name}</p>
                </div>
              </div>
              <div className="flex items-center space-x-3">
                <Tooltip content="Upgrade to Premium for multi-region support">
                  <button
                    onClick={() => window.location.href = '/packages'}
                    className="bg-white/20 hover:bg-white/30 text-white px-4 py-2 rounded-lg transition-colors"
                  >
                    Upgrade Package
                  </button>
                </Tooltip>
                <button
                  onClick={handleRefresh}
                  disabled={loading}
                  className="flex items-center space-x-2 bg-white/20 hover:bg-white/30 text-white px-4 py-2 rounded-lg transition-colors disabled:opacity-50"
                >
                  <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
                  <span>Refresh</span>
                </button>
              </div>
            </div>
          </div>
        </div>

        <div className="max-w-7xl mx-auto px-4 py-8">
          {/* Quick Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-8">
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <Server className="w-8 h-8 text-blue-600" />
                <Tooltip content="All your Azure resources are running">
                  <span className="text-sm text-green-600 font-semibold">All Running</span>
                </Tooltip>
              </div>
              <div className="text-2xl font-bold text-gray-900">{myResources.length}</div>
              <div className="text-sm text-gray-600">Active Resources</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <Activity className="w-8 h-8 text-green-600" />
                <span className="text-sm text-blue-600 font-semibold">Healthy</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">100%</div>
              <div className="text-sm text-gray-600">Uptime</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <DollarSign className="w-8 h-8 text-yellow-600" />
                <Tooltip content="Actual cost for today based on usage">
                  <span className="text-sm text-gray-600 font-semibold">Today</span>
                </Tooltip>
              </div>
              <div className="text-2xl font-bold text-gray-900">${myCosts.daily.toFixed(2)}</div>
              <div className="text-sm text-gray-600">Daily Cost</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <TrendingUp className="w-8 h-8 text-purple-600" />
                <span className="text-sm text-red-600 font-semibold">↑ 12%</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">${myCosts.thisMonth.toFixed(2)}</div>
              <div className="text-sm text-gray-600">This Month</div>
            </div>
          </div>

          {/* Cost Breakdown & Savings */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            <CostBreakdown />
            <SavingsRecommendations />
          </div>

          {/* My Resources */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 mb-6">
            <div className="p-6 border-b border-gray-200">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-2">
                  <h2 className="text-xl font-bold text-gray-900 flex items-center">
                    <Server className="w-6 h-6 mr-2" />
                    My Resources
                  </h2>
                  <Tooltip content="All Azure resources deployed in your infrastructure" showIcon />
                </div>
                <a 
                  href="https://portal.azure.com"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-blue-600 hover:text-blue-700 flex items-center text-sm font-semibold transition-colors"
                >
                  Open Azure Portal
                  <ExternalLink className="w-4 h-4 ml-1" />
                </a>
              </div>
            </div>
            
            {myResources.length > 0 ? (
              <div className="overflow-x-auto">
                <table className="w-full">
                  <thead className="bg-gray-50 border-b border-gray-200">
                    <tr>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Resource</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Region</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Daily Cost</th>
                      <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="bg-white divide-y divide-gray-200">
                    {myResources.map((resource, index) => (
                      <tr key={index} className="hover:bg-gray-50 transition-colors">
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="font-medium text-gray-900">{resource.name}</div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">{resource.type}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-600">{resource.region}</td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className={`inline-flex items-center space-x-2 px-3 py-1 rounded-full ${getStatusColor(resource.status)}`}>
                            {getStatusIcon(resource.status)}
                            <span className="text-sm font-medium capitalize">{resource.status}</span>
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">${resource.cost.toFixed(2)}</td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm">
                          <Tooltip content="View resource details">
                            <button className="text-blue-600 hover:text-blue-700 transition-colors" title="View Details">
                              <FileText className="w-4 h-4" />
                            </button>
                          </Tooltip>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            ) : (
              <EmptyState 
                type="resources"
                onAction={() => window.location.href = '/packages'}
              />
            )}
          </div>

          {/* My Deployments */}
          <div className="bg-white rounded-xl shadow-sm border border-gray-200 mb-6">
            <div className="p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900 flex items-center">
                <Activity className="w-6 h-6 mr-2" />
                Deployment History
              </h2>
            </div>
            <div className="p-6">
              {myDeployments.length > 0 ? (
                <div className="space-y-4">
                  {myDeployments.map((deployment) => (
                    <div key={deployment.id} className="flex items-center justify-between p-4 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
                      <div className="flex items-center space-x-4">
                        <CheckCircle2 className="w-8 h-8 text-green-500" />
                        <div>
                          <div className="font-semibold text-gray-900">{deployment.deployment_name}</div>
                          <div className="text-sm text-gray-600">Started {new Date(deployment.started_at).toLocaleString()}</div>
                        </div>
                      </div>
                      <div className="text-right">
                        <div className="text-sm font-medium text-gray-900 capitalize">{deployment.status}</div>
                        <div className="text-xs text-gray-500">{currentCustomer.package} package</div>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <EmptyState 
                  type="deployments"
                  onAction={() => window.location.href = '/packages'}
                />
              )}
            </div>
          </div>

          {/* Cost Summary */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-6 text-white hover:shadow-xl transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <DollarSign className="w-8 h-8" />
                <Zap className="w-6 h-6 opacity-75" />
              </div>
              <div className="text-3xl font-bold mb-2">${myCosts.monthly.toFixed(2)}</div>
              <div className="text-blue-100">Projected Monthly</div>
            </div>

            <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-xl p-6 text-white hover:shadow-xl transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <Database className="w-8 h-8" />
                <CheckCircle2 className="w-6 h-6 opacity-75" />
              </div>
              <div className="text-3xl font-bold mb-2">{myResources.length}</div>
              <div className="text-green-100">Active Resources</div>
            </div>

            <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-6 text-white hover:shadow-xl transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <Activity className="w-8 h-8" />
                <TrendingUp className="w-6 h-6 opacity-75" />
              </div>
              <div className="text-3xl font-bold mb-2">100%</div>
              <div className="text-purple-100">Uptime</div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default CustomerDashboard;
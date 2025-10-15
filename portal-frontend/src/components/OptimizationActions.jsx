import React from 'react';
import { Zap, Server, HardDrive, Database, Shield, CheckCircle2 } from 'lucide-react';

const OptimizationActions = () => {
  const actions = [
    {
      id: 1,
      title: 'Downsize Underutilized VMs',
      description: '3 VMs running below 10% CPU - recommend smaller SKUs',
      impact: '$1,245/month',
      effort: 'Low',
      risk: 'Low',
      icon: Server,
      color: 'blue',
      resources: ['vm-prod-web-03', 'vm-dev-app-01', 'vm-staging-api'],
      implemented: false
    },
    {
      id: 2,
      title: 'Delete Unattached Disks',
      description: '8 orphaned managed disks consuming storage',
      impact: '$127/month',
      effort: 'Very Low',
      risk: 'Very Low',
      icon: HardDrive,
      color: 'green',
      resources: ['disk-old-backup-01', 'disk-temp-data', '+6 more'],
      implemented: false
    },
    {
      id: 3,
      title: 'Enable Auto-Shutdown for Dev VMs',
      description: 'Dev/Test VMs running 24/7 - enable auto-shutdown at 7 PM',
      impact: '$892/month',
      effort: 'Low',
      risk: 'Very Low',
      icon: Zap,
      color: 'yellow',
      resources: ['dev-environment-01', 'test-server-02', '+3 more'],
      implemented: false
    },
    {
      id: 4,
      title: 'Switch to Reserved Instances',
      description: 'Production VMs eligible for 1-year RI commitment',
      impact: '$1,450/month',
      effort: 'Medium',
      risk: 'Medium',
      icon: Shield,
      color: 'purple',
      resources: ['vm-prod-web-01', 'vm-prod-web-02', 'vm-prod-api'],
      implemented: true
    },
    {
      id: 5,
      title: 'Archive Cold Storage Data',
      description: 'Move 2.3 TB of cold data to Archive tier',
      impact: '$156/month',
      effort: 'Low',
      risk: 'Low',
      icon: Database,
      color: 'indigo',
      resources: ['storage-logs-2022', 'storage-backups-old'],
      implemented: false
    }
  ];

  const getEffortColor = (effort) => {
    const colors = {
      'Very Low': 'bg-green-100 text-green-700',
      'Low': 'bg-blue-100 text-blue-700',
      'Medium': 'bg-yellow-100 text-yellow-700',
      'High': 'bg-red-100 text-red-700'
    };
    return colors[effort] || 'bg-gray-100 text-gray-700';
  };

  const handleImplement = (actionId) => {
    alert(`Implementing optimization action #${actionId}`);
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Optimization Actions</h3>
            <p className="text-sm text-gray-600 mt-1">AI-recommended cost reduction opportunities</p>
          </div>
          <div className="text-right">
            <div className="text-2xl font-bold text-green-600">$3,870</div>
            <div className="text-xs text-gray-600">Available Savings/mo</div>
          </div>
        </div>
      </div>

      <div className="divide-y divide-gray-200 max-h-[600px] overflow-y-auto">
        {actions.map((action) => {
          const Icon = action.icon;
          
          return (
            <div key={action.id} className={`p-6 ${action.implemented ? 'bg-green-50' : 'hover:bg-gray-50'} transition-colors`}>
              <div className="flex items-start justify-between">
                <div className="flex items-start space-x-4 flex-1">
                  <div className={`p-3 rounded-lg bg-${action.color}-100`}>
                    <Icon className={`w-6 h-6 text-${action.color}-600`} />
                  </div>
                  
                  <div className="flex-1">
                    <div className="flex items-center space-x-3 mb-2">
                      <h4 className="font-semibold text-gray-900">{action.title}</h4>
                      {action.implemented && (
                        <span className="flex items-center space-x-1 px-2 py-1 text-xs font-semibold rounded-full bg-green-100 text-green-700">
                          <CheckCircle2 className="w-3 h-3" />
                          <span>Implemented</span>
                        </span>
                      )}
                    </div>
                    
                    <p className="text-sm text-gray-600 mb-3">{action.description}</p>
                    
                    <div className="flex items-center space-x-4 text-xs mb-3">
                      <span className={`px-2 py-1 rounded-full font-semibold ${getEffortColor(action.effort)}`}>
                        Effort: {action.effort}
                      </span>
                      <span className={`px-2 py-1 rounded-full font-semibold ${getEffortColor(action.risk)}`}>
                        Risk: {action.risk}
                      </span>
                      <span className="font-bold text-green-600 text-sm">{action.impact} savings</span>
                    </div>
                    
                    <div className="text-xs text-gray-500">
                      Affected: {action.resources.join(', ')}
                    </div>
                  </div>
                </div>
                
                <div className="ml-4">
                  {!action.implemented ? (
                    <button
                      onClick={() => handleImplement(action.id)}
                      className="flex items-center space-x-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors text-sm font-semibold"
                    >
                      <Zap className="w-4 h-4" />
                      <span>Implement</span>
                    </button>
                  ) : (
                    <div className="px-4 py-2 rounded-lg bg-green-100 text-green-700 text-sm font-semibold">
                      Active
                    </div>
                  )}
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default OptimizationActions;
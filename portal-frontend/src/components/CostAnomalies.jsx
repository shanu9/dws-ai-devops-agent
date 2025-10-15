import React from 'react';
import { AlertTriangle, TrendingUp, Activity } from 'lucide-react';

const CostAnomalies = () => {
  const anomalies = [
    {
      id: 1,
      resource: 'prod-storage-01',
      type: 'Unusual Spike',
      description: 'Storage costs increased 340% in last 48 hours',
      impact: '$127/day',
      severity: 'high',
      detected: '2 hours ago'
    },
    {
      id: 2,
      resource: 'vm-prod-web-03',
      type: 'Underutilized',
      description: 'VM running at 5% CPU for 7 days',
      impact: '$45/day wasted',
      severity: 'medium',
      detected: '1 day ago'
    },
    {
      id: 3,
      resource: 'sql-prod-db',
      type: 'Trend Change',
      description: 'Database costs trending 15% higher than forecast',
      impact: '$23/day',
      severity: 'low',
      detected: '3 days ago'
    }
  ];

  const getSeverityColor = (severity) => {
    const colors = {
      high: 'text-red-600 bg-red-100 border-red-200',
      medium: 'text-yellow-600 bg-yellow-100 border-yellow-200',
      low: 'text-blue-600 bg-blue-100 border-blue-200'
    };
    return colors[severity];
  };

  const getSeverityIcon = (severity) => {
    if (severity === 'high') return <AlertTriangle className="w-5 h-5" />;
    if (severity === 'medium') return <TrendingUp className="w-5 h-5" />;
    return <Activity className="w-5 h-5" />;
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Cost Anomalies</h3>
            <p className="text-sm text-gray-600 mt-1">AI-detected unusual spending patterns</p>
          </div>
          <div className="flex items-center space-x-2">
            <span className="px-3 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-600">
              {anomalies.filter(a => a.severity === 'high').length} High
            </span>
          </div>
        </div>
      </div>

      <div className="divide-y divide-gray-200">
        {anomalies.map((anomaly) => (
          <div key={anomaly.id} className="p-6 hover:bg-gray-50 transition-colors">
            <div className="flex items-start justify-between">
              <div className="flex items-start space-x-4 flex-1">
                <div className={`p-2 rounded-lg border ${getSeverityColor(anomaly.severity)}`}>
                  {getSeverityIcon(anomaly.severity)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    <h4 className="font-semibold text-gray-900">{anomaly.type}</h4>
                    <span className={`px-2 py-1 text-xs font-semibold rounded-full uppercase ${getSeverityColor(anomaly.severity)}`}>
                      {anomaly.severity}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mb-3">{anomaly.description}</p>
                  <div className="flex items-center space-x-4 text-xs text-gray-500">
                    <span>Resource: <span className="font-mono font-semibold text-gray-700">{anomaly.resource}</span></span>
                    <span>•</span>
                    <span className="font-semibold text-red-600">{anomaly.impact}</span>
                    <span>•</span>
                    <span>{anomaly.detected}</span>
                  </div>
                </div>
              </div>
              <button className="ml-4 text-blue-600 hover:text-blue-700 text-sm font-semibold">
                Investigate
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default CostAnomalies;
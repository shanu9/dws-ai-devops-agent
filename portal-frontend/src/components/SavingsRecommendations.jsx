import React from 'react';
import { TrendingDown, Zap, CheckCircle2, AlertTriangle } from 'lucide-react';

const SavingsRecommendations = () => {
  // Mock data - replace with AI Cost Optimizer API
  const recommendations = [
    {
      id: 1,
      title: 'Switch to Reserved Instances',
      description: 'Save 40% on VM costs with 1-year commitment',
      savings: 1200,
      savingsPercent: 40,
      impact: 'high',
      risk: 'low',
      resources: ['VM-Production-1', 'VM-Production-2'],
      actionable: true
    },
    {
      id: 2,
      title: 'Use Spot VMs for Dev/Test',
      description: 'Non-critical workloads can use spot instances',
      savings: 450,
      savingsPercent: 70,
      impact: 'medium',
      risk: 'medium',
      resources: ['VM-Dev-1'],
      actionable: true
    },
    {
      id: 3,
      title: 'Enable Storage Lifecycle',
      description: 'Move old data to cool/archive tiers',
      savings: 180,
      savingsPercent: 60,
      impact: 'low',
      risk: 'low',
      resources: ['Storage Account'],
      actionable: true
    },
    {
      id: 4,
      title: 'Rightsize Firewall SKU',
      description: 'Current usage suggests Standard tier is sufficient',
      savings: 320,
      savingsPercent: 25,
      impact: 'medium',
      risk: 'low',
      resources: ['Azure Firewall'],
      actionable: false
    }
  ];

  const getImpactColor = (impact) => {
    if (impact === 'high') return 'bg-green-100 text-green-800';
    if (impact === 'medium') return 'bg-yellow-100 text-yellow-800';
    return 'bg-gray-100 text-gray-800';
  };

  const getRiskColor = (risk) => {
    if (risk === 'low') return 'bg-green-100 text-green-700';
    if (risk === 'medium') return 'bg-yellow-100 text-yellow-700';
    return 'bg-red-100 text-red-700';
  };

  const totalSavings = recommendations.reduce((sum, r) => sum + r.savings, 0);

  return (
    <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h3 className="text-lg font-bold text-gray-900">Savings Recommendations</h3>
          <p className="text-sm text-gray-600 mt-1">AI-powered cost optimization suggestions</p>
        </div>
        <div className="text-right">
          <p className="text-sm text-gray-600">Potential Monthly Savings</p>
          <p className="text-3xl font-bold text-green-600">${totalSavings.toLocaleString()}</p>
        </div>
      </div>

      <div className="space-y-4">
        {recommendations.map((rec) => (
          <div 
            key={rec.id} 
            className="p-4 border-2 border-gray-200 rounded-lg hover:border-blue-300 transition-colors"
          >
            <div className="flex items-start justify-between mb-3">
              <div className="flex-1">
                <div className="flex items-center space-x-2 mb-2">
                  <TrendingDown className="w-5 h-5 text-green-600" />
                  <h4 className="font-semibold text-gray-900">{rec.title}</h4>
                </div>
                <p className="text-sm text-gray-600">{rec.description}</p>
              </div>
              <div className="text-right ml-4">
                <p className="text-2xl font-bold text-green-600">
                  ${rec.savings}
                </p>
                <p className="text-xs text-gray-500">per month</p>
              </div>
            </div>

            <div className="flex items-center space-x-2 mb-3">
              <span className={`text-xs font-semibold px-2 py-1 rounded-full ${getImpactColor(rec.impact)}`}>
                {rec.impact.toUpperCase()} IMPACT
              </span>
              <span className={`text-xs font-semibold px-2 py-1 rounded-full ${getRiskColor(rec.risk)}`}>
                {rec.risk.toUpperCase()} RISK
              </span>
              <span className="text-xs text-gray-500">
                Saves {rec.savingsPercent}%
              </span>
            </div>

            <div className="flex items-center justify-between">
              <div className="text-xs text-gray-500">
                Affects: {rec.resources.join(', ')}
              </div>
              {rec.actionable ? (
                <button className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white text-sm font-semibold rounded-lg hover:bg-blue-700 transition-colors">
                  <Zap className="w-4 h-4" />
                  <span>Apply Now</span>
                </button>
              ) : (
                <button className="flex items-center space-x-2 px-4 py-2 bg-gray-100 text-gray-600 text-sm font-semibold rounded-lg cursor-not-allowed">
                  <AlertTriangle className="w-4 h-4" />
                  <span>Manual Review</span>
                </button>
              )}
            </div>
          </div>
        ))}
      </div>

      <div className="mt-6 p-4 bg-green-50 rounded-lg border border-green-200">
        <div className="flex items-center space-x-2">
          <CheckCircle2 className="w-5 h-5 text-green-600" />
          <p className="text-sm font-semibold text-green-900">
            Implement all recommendations to save ${totalSavings}/month (${(totalSavings * 12).toLocaleString()}/year)
          </p>
        </div>
      </div>
    </div>
  );
};

export default SavingsRecommendations;
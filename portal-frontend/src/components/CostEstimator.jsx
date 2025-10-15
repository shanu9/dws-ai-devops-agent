import React from 'react';
import { DollarSign, TrendingUp, Calendar, PieChart } from 'lucide-react';

const CostEstimator = ({ items }) => {
  const serviceCosts = {
    virtual_machine: 145.50,
    app_service: 75.00,
    virtual_network: 15.00,
    firewall: 650.00,
    storage_account: 23.50,
    sql_database: 350.00,
    key_vault: 8.00,
    log_analytics: 45.00,
    application_gateway: 180.00,
    cosmos_db: 450.00
  };

  const calculateCosts = () => {
    const breakdown = {};
    let total = 0;

    items.forEach(item => {
      const cost = serviceCosts[item.type] || 0;
      total += cost;
      
      if (breakdown[item.type]) {
        breakdown[item.type].count++;
        breakdown[item.type].total += cost;
      } else {
        breakdown[item.type] = {
          name: item.name,
          count: 1,
          unitCost: cost,
          total: cost
        };
      }
    });

    return { total, breakdown: Object.entries(breakdown) };
  };

  const { total, breakdown } = calculateCosts();
  const annualCost = total * 12;

  return (
    <div className="h-full flex flex-col">
      <div className="p-4 border-b border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900 mb-2">Cost Estimate</h3>
        <p className="text-sm text-gray-600">Real-time cost calculation</p>
      </div>

      <div className="p-4 space-y-4">
        {/* Monthly Cost Card */}
        <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-xl p-4 text-white">
          <div className="flex items-center justify-between mb-2">
            <DollarSign className="w-6 h-6" />
            <TrendingUp className="w-5 h-5 opacity-75" />
          </div>
          <div className="text-3xl font-bold mb-1">${total.toFixed(2)}</div>
          <div className="text-blue-100 text-sm">Monthly Cost</div>
        </div>

        {/* Annual Cost Card */}
        <div className="bg-gradient-to-br from-purple-500 to-purple-600 rounded-xl p-4 text-white">
          <div className="flex items-center justify-between mb-2">
            <Calendar className="w-6 h-6" />
            <span className="text-xs bg-white/20 px-2 py-1 rounded-full">12 months</span>
          </div>
          <div className="text-2xl font-bold mb-1">${annualCost.toFixed(0)}</div>
          <div className="text-purple-100 text-sm">Annual Cost</div>
        </div>

        {/* Resource Count */}
        <div className="bg-white border border-gray-200 rounded-lg p-4">
          <div className="flex items-center justify-between">
            <div>
              <div className="text-2xl font-bold text-gray-900">{items.length}</div>
              <div className="text-sm text-gray-600">Resources</div>
            </div>
            <PieChart className="w-8 h-8 text-blue-600" />
          </div>
        </div>

        {/* Cost Breakdown */}
        {breakdown.length > 0 && (
          <div className="bg-white border border-gray-200 rounded-lg">
            <div className="p-4 border-b border-gray-200">
              <h4 className="font-semibold text-gray-900">Cost Breakdown</h4>
            </div>
            <div className="divide-y divide-gray-200 max-h-80 overflow-y-auto">
              {breakdown.map(([type, data]) => (
                <div key={type} className="p-4">
                  <div className="flex items-center justify-between mb-2">
                    <div className="font-medium text-gray-900 text-sm">
                      {data.name}
                    </div>
                    <div className="text-sm font-bold text-gray-900">
                      ${data.total.toFixed(2)}
                    </div>
                  </div>
                  <div className="flex items-center justify-between text-xs text-gray-500">
                    <span>{data.count}x ${data.unitCost.toFixed(2)}</span>
                    <span>{((data.total / total) * 100).toFixed(1)}%</span>
                  </div>
                  <div className="mt-2 w-full h-1.5 bg-gray-100 rounded-full overflow-hidden">
                    <div 
                      className="h-full bg-blue-500 transition-all duration-300"
                      style={{ width: `${(data.total / total) * 100}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {items.length === 0 && (
          <div className="text-center py-8">
            <DollarSign className="w-12 h-12 text-gray-300 mx-auto mb-2" />
            <p className="text-gray-500 text-sm">Add services to see cost estimate</p>
          </div>
        )}

        {/* Savings Tip */}
        {total > 500 && (
          <div className="bg-green-50 border border-green-200 rounded-lg p-4">
            <div className="text-sm font-semibold text-green-900 mb-1">💡 Savings Tip</div>
            <div className="text-xs text-green-700">
              Consider Reserved Instances to save up to 40% on compute costs
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default CostEstimator;
import React from 'react';
import { Server, Database, Cloud, Shield, Zap } from 'lucide-react';

const CostBreakdown = ({ costs }) => {
  // Mock data - replace with real Azure Cost Management API data
  const services = [
    { name: 'Azure Firewall', cost: 48.00, percentage: 41, icon: Shield, color: 'blue' },
    { name: 'Virtual Networks', cost: 27.80, percentage: 24, icon: Cloud, color: 'green' },
    { name: 'Log Analytics', cost: 18.50, percentage: 16, icon: Database, color: 'purple' },
    { name: 'Bastion', cost: 12.00, percentage: 10, icon: Server, color: 'yellow' },
    { name: 'Other Services', cost: 10.20, percentage: 9, icon: Zap, color: 'gray' }
  ];

  const getColorClasses = (color) => {
    const colors = {
      blue: { bg: 'bg-blue-500', text: 'text-blue-600', light: 'bg-blue-50' },
      green: { bg: 'bg-green-500', text: 'text-green-600', light: 'bg-green-50' },
      purple: { bg: 'bg-purple-500', text: 'text-purple-600', light: 'bg-purple-50' },
      yellow: { bg: 'bg-yellow-500', text: 'text-yellow-600', light: 'bg-yellow-50' },
      gray: { bg: 'bg-gray-500', text: 'text-gray-600', light: 'bg-gray-50' }
    };
    return colors[color];
  };

  return (
    <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
      <h3 className="text-lg font-bold text-gray-900 mb-6">Cost Breakdown by Service</h3>
      
      {/* Horizontal Bar Chart */}
      <div className="space-y-4">
        {services.map((service, index) => {
          const colors = getColorClasses(service.color);
          const Icon = service.icon;
          
          return (
            <div key={index}>
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center space-x-2">
                  <Icon className={`w-4 h-4 ${colors.text}`} />
                  <span className="text-sm font-medium text-gray-700">{service.name}</span>
                </div>
                <div className="flex items-center space-x-3">
                  <span className="text-sm text-gray-500">{service.percentage}%</span>
                  <span className="text-sm font-bold text-gray-900">${service.cost.toFixed(2)}</span>
                </div>
              </div>
              
              {/* Progress Bar */}
              <div className="w-full h-2 bg-gray-100 rounded-full overflow-hidden">
                <div 
                  className={`h-full ${colors.bg} transition-all duration-500`}
                  style={{ width: `${service.percentage}%` }}
                />
              </div>
            </div>
          );
        })}
      </div>

      {/* Total */}
      <div className="mt-6 pt-6 border-t border-gray-200">
        <div className="flex items-center justify-between">
          <span className="text-base font-semibold text-gray-900">Total Daily Cost</span>
          <span className="text-2xl font-bold text-gray-900">
            ${services.reduce((sum, s) => sum + s.cost, 0).toFixed(2)}
          </span>
        </div>
        <div className="flex items-center justify-between mt-2">
          <span className="text-sm text-gray-600">Projected Monthly</span>
          <span className="text-lg font-bold text-blue-600">
            ${(services.reduce((sum, s) => sum + s.cost, 0) * 30).toFixed(2)}
          </span>
        </div>
      </div>
    </div>
  );
};

export default CostBreakdown;
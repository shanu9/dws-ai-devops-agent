import React from 'react';
import { TrendingDown, DollarSign, Target, Calendar } from 'lucide-react';

const SavingsTracker = () => {
  const savingsData = {
    thisMonth: 1245.00,
    lastMonth: 980.00,
    yearToDate: 8950.00,
    target: 12000.00,
    implemented: [
      { date: '2025-10-12', action: 'Reserved Instances', amount: 450.00 },
      { date: '2025-10-08', action: 'Delete Unattached Disks', amount: 127.00 },
      { date: '2025-10-05', action: 'Downsize 2 VMs', amount: 320.00 },
      { date: '2025-10-01', action: 'Archive Cold Storage', amount: 156.00 }
    ]
  };

  const progressPercentage = (savingsData.yearToDate / savingsData.target) * 100;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200">
      <div className="p-6 border-b border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900">Savings Tracker</h3>
        <p className="text-sm text-gray-600 mt-1">Track your optimization ROI</p>
      </div>

      <div className="p-6 space-y-6">
        <div>
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm text-gray-600">YTD Savings Goal</span>
            <span className="text-sm font-bold text-gray-900">{progressPercentage.toFixed(0)}%</span>
          </div>
          <div className="relative w-full h-3 bg-gray-200 rounded-full overflow-hidden">
            <div 
              className="absolute top-0 left-0 h-full bg-gradient-to-r from-green-500 to-green-600 transition-all duration-500"
              style={{ width: `${Math.min(progressPercentage, 100)}%` }}
            />
          </div>
          <div className="flex items-center justify-between mt-2 text-xs text-gray-500">
            <span>${savingsData.yearToDate.toFixed(0)} saved</span>
            <span>${savingsData.target.toFixed(0)} target</span>
          </div>
        </div>

        <div className="grid grid-cols-1 gap-4">
          <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-lg p-4 text-white">
            <div className="flex items-center justify-between mb-2">
              <DollarSign className="w-6 h-6" />
              <TrendingDown className="w-5 h-5 opacity-75" />
            </div>
            <div className="text-2xl font-bold">${savingsData.thisMonth.toFixed(2)}</div>
            <div className="text-green-100 text-sm">This Month</div>
          </div>

          <div className="bg-gradient-to-br from-blue-500 to-blue-600 rounded-lg p-4 text-white">
            <div className="flex items-center justify-between mb-2">
              <Calendar className="w-6 h-6" />
              <Target className="w-5 h-5 opacity-75" />
            </div>
            <div className="text-2xl font-bold">${savingsData.yearToDate.toFixed(0)}</div>
            <div className="text-blue-100 text-sm">Year to Date</div>
          </div>
        </div>

        <div>
          <h4 className="text-sm font-semibold text-gray-900 mb-3">Recent Implementations</h4>
          <div className="space-y-3">
            {savingsData.implemented.map((item, index) => (
              <div key={index} className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <div className="text-sm font-medium text-gray-900">{item.action}</div>
                  <div className="text-xs text-gray-500">{new Date(item.date).toLocaleDateString()}</div>
                </div>
                <div className="text-sm font-bold text-green-600">
                  +${item.amount.toFixed(2)}
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
          <div className="text-sm text-gray-900 mb-1">
            <span className="font-semibold">Projected Annual:</span>
          </div>
          <div className="text-2xl font-bold text-purple-600">
            ${(savingsData.thisMonth * 12).toFixed(0)}
          </div>
          <div className="text-xs text-gray-600 mt-1">
            Based on current month's rate
          </div>
        </div>
      </div>
    </div>
  );
};

export default SavingsTracker;
import React, { useState, useEffect } from 'react';
import { DollarSign, TrendingUp, TrendingDown, Calendar } from 'lucide-react';

const CostWidget = () => {
  const [costData, setCostData] = useState({
    today: 116.50,
    yesterday: 104.30,
    monthToDate: 3247.80,
    projected: 8950.00,
    trend: 11.7
  });

  useEffect(() => {
    // Mock API call - replace with real Azure Cost Management API
    const fetchCostData = async () => {
      try {
        // Simulated data
        setCostData({
          today: 116.50,
          yesterday: 104.30,
          monthToDate: 3247.80,
          projected: 8950.00,
          trend: 11.7
        });
      } catch (error) {
        console.error('Failed to fetch cost data:', error);
      }
    };

    fetchCostData();
  }, []);

  // Safe number formatting
  const formatCurrency = (value) => {
    if (value === null || value === undefined || isNaN(value)) {
      return '$0.00';
    }
    return `$${Number(value).toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
  };

  const formatTrend = (value) => {
    if (value === null || value === undefined || isNaN(value)) {
      return '0%';
    }
    return `${value > 0 ? '+' : ''}${Number(value).toFixed(1)}%`;
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
      <div className="flex items-center justify-between mb-6">
        <h3 className="text-lg font-semibold text-gray-900">Cost Overview</h3>
        <div className={`flex items-center space-x-1 ${costData.trend >= 0 ? 'text-red-600' : 'text-green-600'}`}>
          {costData.trend >= 0 ? <TrendingUp className="w-5 h-5" /> : <TrendingDown className="w-5 h-5" />}
          <span className="text-sm font-semibold">{formatTrend(costData.trend)}</span>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-6">
        <div>
          <div className="flex items-center space-x-2 text-gray-600 mb-2">
            <DollarSign className="w-4 h-4" />
            <span className="text-sm">Today</span>
          </div>
          <div className="text-3xl font-bold text-gray-900">{formatCurrency(costData.today)}</div>
          <div className="text-xs text-gray-500 mt-1">
            Yesterday: {formatCurrency(costData.yesterday)}
          </div>
        </div>

        <div>
          <div className="flex items-center space-x-2 text-gray-600 mb-2">
            <Calendar className="w-4 h-4" />
            <span className="text-sm">Month to Date</span>
          </div>
          <div className="text-3xl font-bold text-gray-900">{formatCurrency(costData.monthToDate)}</div>
          <div className="text-xs text-gray-500 mt-1">
            Projected: {formatCurrency(costData.projected)}
          </div>
        </div>
      </div>

      <div className="mt-6 pt-6 border-t border-gray-200">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-600">Daily Average</span>
          <span className="font-semibold text-gray-900">
            {formatCurrency(costData.monthToDate / new Date().getDate())}
          </span>
        </div>
      </div>
    </div>
  );
};

export default CostWidget;
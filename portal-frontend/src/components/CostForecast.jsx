import React from 'react';
import { TrendingUp, Calendar, Brain } from 'lucide-react';

const CostForecast = () => {
  const historicalData = [
    { month: 'Aug', actual: 2850, forecast: null },
    { month: 'Sep', actual: 2920, forecast: null },
    { month: 'Oct', actual: 3150, forecast: null },
    { month: 'Nov', actual: null, forecast: 3380 },
    { month: 'Dec', actual: null, forecast: 3520 },
    { month: 'Jan', actual: null, forecast: 3450 }
  ];

  const maxValue = 4000;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Cost Forecast</h3>
            <p className="text-sm text-gray-600 mt-1">AI-powered predictive analytics</p>
          </div>
          <div className="flex items-center space-x-2 text-sm">
            <Brain className="w-4 h-4 text-purple-600" />
            <span className="text-purple-600 font-semibold">ML Model v2.3</span>
          </div>
        </div>
      </div>

      <div className="p-6">
        <div className="space-y-4 mb-6">
          {historicalData.map((data, index) => {
            const value = data.actual || data.forecast;
            const percentage = (value / maxValue) * 100;
            const isActual = data.actual !== null;
            
            return (
              <div key={index}>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-sm font-medium text-gray-700">{data.month}</span>
                  <div className="flex items-center space-x-2">
                    <span className="text-sm font-bold text-gray-900">${value}</span>
                    {!isActual && (
                      <span className="px-2 py-0.5 text-xs font-semibold rounded-full bg-purple-100 text-purple-600">
                        Forecast
                      </span>
                    )}
                  </div>
                </div>
                <div className="relative w-full h-8 bg-gray-100 rounded-lg overflow-hidden">
                  <div 
                    className={`absolute top-0 left-0 h-full transition-all duration-500 ${
                      isActual 
                        ? 'bg-gradient-to-r from-blue-500 to-blue-600' 
                        : 'bg-gradient-to-r from-purple-400 to-purple-500 opacity-70'
                    }`}
                    style={{ width: `${percentage}%` }}
                  />
                  {!isActual && (
                    <div className="absolute inset-0 flex items-center justify-end pr-3">
                      <TrendingUp className="w-4 h-4 text-white" />
                    </div>
                  )}
                </div>
              </div>
            );
          })}
        </div>

        <div className="bg-purple-50 border border-purple-200 rounded-lg p-4">
          <div className="flex items-start space-x-3">
            <Calendar className="w-5 h-5 text-purple-600 mt-0.5" />
            <div>
              <div className="font-semibold text-gray-900 mb-1">3-Month Forecast</div>
              <div className="text-sm text-gray-600">
                Expected spend: <span className="font-bold text-gray-900">$10,350</span> • 
                Confidence: <span className="font-bold text-green-600">94%</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default CostForecast;
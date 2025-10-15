import React from 'react';
import { Shield, TrendingUp, TrendingDown } from 'lucide-react';

const ComplianceScore = ({ score, framework, lastScan }) => {
  const getScoreColor = (score) => {
    if (score >= 90) return 'text-green-600';
    if (score >= 75) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getScoreGradient = (score) => {
    if (score >= 90) return 'from-green-500 to-green-600';
    if (score >= 75) return 'from-yellow-500 to-yellow-600';
    return 'from-red-500 to-red-600';
  };

  const trend = score >= 85 ? 2.3 : -1.5;

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-lg font-semibold text-gray-900">Compliance Score</h3>
        <Shield className="w-5 h-5 text-gray-400" />
      </div>

      <div className="text-center mb-6">
        <div className={`text-6xl font-bold mb-2 bg-gradient-to-r ${getScoreGradient(score)} bg-clip-text text-transparent`}>
          {score}%
        </div>
        <div className="text-sm text-gray-600">{framework}</div>
      </div>

      <div className="relative w-full h-3 bg-gray-200 rounded-full overflow-hidden mb-6">
        <div 
          className={`absolute top-0 left-0 h-full bg-gradient-to-r ${getScoreGradient(score)} transition-all duration-500`}
          style={{ width: `${score}%` }}
        />
      </div>

      <div className="space-y-3">
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-600">Target Score</span>
          <span className="font-semibold text-gray-900">95%</span>
        </div>
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-600">Last 30 Days</span>
          <div className={`flex items-center space-x-1 ${trend >= 0 ? 'text-green-600' : 'text-red-600'}`}>
            {trend >= 0 ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
            <span className="font-semibold">{trend > 0 ? '+' : ''}{trend}%</span>
          </div>
        </div>
        <div className="flex items-center justify-between text-sm">
          <span className="text-gray-600">Last Scan</span>
          <span className="font-semibold text-gray-900">
            {new Date(lastScan).toLocaleDateString()}
          </span>
        </div>
      </div>

      <div className="mt-6 pt-6 border-t border-gray-200">
        <div className={`text-center text-sm font-semibold ${getScoreColor(score)}`}>
          {score >= 90 ? '✓ Excellent Compliance' : score >= 75 ? '⚠ Needs Attention' : '✗ Critical Issues'}
        </div>
      </div>
    </div>
  );
};

export default ComplianceScore;
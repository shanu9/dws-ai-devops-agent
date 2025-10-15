import React, { useState, useEffect } from 'react';
import { 
  Brain, 
  TrendingDown, 
  Zap,
  DollarSign,
  RefreshCw,
  CheckCircle2,
  AlertTriangle,
  Target
} from 'lucide-react';
import Navigation from '../components/Navigation';
import CostAnomalies from '../components/CostAnomalies';
import CostForecast from '../components/CostForecast';
import OptimizationActions from '../components/OptimizationActions';
import SavingsTracker from '../components/SavingsTracker';

const CostOptimizer = () => {
  const [analysisRunning, setAnalysisRunning] = useState(false);
  const [optimizationData, setOptimizationData] = useState({
    potentialSavings: 2847.50,
    implementedSavings: 1250.00,
    recommendations: 12,
    anomalies: 3,
    lastAnalysis: new Date().toISOString()
  });

  const runAnalysis = async () => {
    setAnalysisRunning(true);
    try {
      // Mock AI analysis
      await new Promise(resolve => setTimeout(resolve, 3000));
      setOptimizationData({
        ...optimizationData,
        lastAnalysis: new Date().toISOString()
      });
    } finally {
      setAnalysisRunning(false);
    }
  };

  return (
    <>
      <Navigation currentPage="optimizer" />
      
      <div className="min-h-screen bg-gray-50">
        <div className="bg-gradient-to-r from-purple-600 to-indigo-600 text-white">
          <div className="max-w-7xl mx-auto px-4 py-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <Brain className="w-8 h-8" />
                <div>
                  <h1 className="text-3xl font-bold">AI Cost Optimizer</h1>
                  <p className="text-purple-100 mt-1">Intelligent cost optimization powered by machine learning</p>
                </div>
              </div>
              <button 
                onClick={runAnalysis}
                disabled={analysisRunning}
                className="flex items-center space-x-2 bg-white text-purple-600 px-6 py-3 rounded-lg hover:bg-purple-50 transition-colors font-semibold disabled:opacity-50"
              >
                <RefreshCw className={`w-5 h-5 ${analysisRunning ? 'animate-spin' : ''}`} />
                <span>{analysisRunning ? 'Analyzing...' : 'Run Analysis'}</span>
              </button>
            </div>
          </div>
        </div>

        <div className="max-w-7xl mx-auto px-4 py-8">
          <div className="grid grid-cols-4 gap-6 mb-8">
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <DollarSign className="w-8 h-8 text-green-600" />
                <TrendingDown className="w-5 h-5 text-green-600" />
              </div>
              <div className="text-2xl font-bold text-gray-900">${optimizationData.potentialSavings.toFixed(2)}</div>
              <div className="text-sm text-gray-600">Potential Monthly Savings</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <CheckCircle2 className="w-8 h-8 text-blue-600" />
                <span className="text-sm text-blue-600 font-semibold">Active</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">${optimizationData.implementedSavings.toFixed(2)}</div>
              <div className="text-sm text-gray-600">Implemented Savings</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <Target className="w-8 h-8 text-purple-600" />
                <span className="text-sm text-purple-600 font-semibold">AI Powered</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">{optimizationData.recommendations}</div>
              <div className="text-sm text-gray-600">Recommendations</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
              <div className="flex items-center justify-between mb-4">
                <AlertTriangle className="w-8 h-8 text-yellow-600" />
                <span className="text-sm text-yellow-600 font-semibold">Detected</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">{optimizationData.anomalies}</div>
              <div className="text-sm text-gray-600">Cost Anomalies</div>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
            <CostForecast />
            <CostAnomalies />
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
            <div className="lg:col-span-2">
              <OptimizationActions />
            </div>
            <div className="lg:col-span-1">
              <SavingsTracker />
            </div>
          </div>

          <div className="bg-gradient-to-br from-purple-500 to-indigo-600 rounded-xl p-6 text-white">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <Brain className="w-12 h-12" />
                <div>
                  <div className="text-xl font-bold">AI Analysis Complete</div>
                  <div className="text-purple-100 mt-1">
                    Last run: {new Date(optimizationData.lastAnalysis).toLocaleString()} • Next: Tomorrow 2:00 AM
                  </div>
                </div>
              </div>
              <div className="text-right">
                <div className="text-3xl font-bold">${optimizationData.potentialSavings.toFixed(0)}</div>
                <div className="text-purple-100">Monthly savings available</div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default CostOptimizer;
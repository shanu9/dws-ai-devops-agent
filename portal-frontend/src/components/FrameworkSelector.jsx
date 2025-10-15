import React from 'react';
import { Shield } from 'lucide-react';

const FrameworkSelector = ({ frameworks, selected, onChange, data }) => {
  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6 mb-8">
      <h3 className="text-lg font-semibold text-gray-900 mb-4">Compliance Frameworks</h3>
      <div className="grid grid-cols-5 gap-4">
        {frameworks.map((framework) => {
          const frameworkData = data[framework.id];
          const isSelected = selected === framework.id;
          
          return (
            <button
              key={framework.id}
              onClick={() => onChange(framework.id)}
              className={`p-4 rounded-xl border-2 transition-all ${
                isSelected ? 'border-blue-500 bg-blue-50' : 'border-gray-200 hover:border-gray-300 bg-white'
              }`}
            >
              <div className="flex flex-col items-center text-center">
                <Shield className={`w-8 h-8 mb-3 ${isSelected ? 'text-blue-600' : 'text-gray-400'}`} />
                <div className="font-semibold text-gray-900 mb-2">{framework.name}</div>
                <div className={`text-2xl font-bold mb-1 ${
                  frameworkData.score >= 90 ? 'text-green-600' : 
                  frameworkData.score >= 75 ? 'text-yellow-600' : 'text-red-600'
                }`}>
                  {frameworkData.score}%
                </div>
                <div className="text-xs text-gray-500">{frameworkData.violations} violations</div>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default FrameworkSelector;
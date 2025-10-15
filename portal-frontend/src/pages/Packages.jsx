import React, { useState, useEffect } from 'react';
import { Check, X, ArrowRight, Loader2 } from 'lucide-react';
import Navigation from '../components/Navigation';

const PackageSelection = () => {
  const [packages, setPackages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedTier, setSelectedTier] = useState('standard');

  useEffect(() => {
    fetchPackages();
  }, []);

  const fetchPackages = async () => {
    try {
      const response = await fetch('http://localhost:8000/api/packages');
      const data = await response.json();
      setPackages(data);
      setLoading(false);
    } catch (error) {
      console.error('Failed to fetch packages:', error);
      setLoading(false);
    }
  };

  const handleContinue = () => {
    window.location.href = `/deploy?package=${selectedTier}`;
  };

  const getColorClasses = (color, isSelected) => {
    const colors = {
      blue: {
        bg: isSelected ? 'bg-blue-50' : 'bg-white',
        border: isSelected ? 'border-blue-500 border-2' : 'border-gray-200',
        badge: 'bg-blue-100 text-blue-800',
        button: 'bg-blue-600 hover:bg-blue-700'
      },
      green: {
        bg: isSelected ? 'bg-green-50' : 'bg-white',
        border: isSelected ? 'border-green-500 border-2' : 'border-gray-200',
        badge: 'bg-green-100 text-green-800',
        button: 'bg-green-600 hover:bg-green-700'
      },
      purple: {
        bg: isSelected ? 'bg-purple-50' : 'bg-white',
        border: isSelected ? 'border-purple-500 border-2' : 'border-gray-200',
        badge: 'bg-purple-100 text-purple-800',
        button: 'bg-purple-600 hover:bg-purple-700'
      }
    };
    return colors[color];
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <Loader2 className="w-8 h-8 animate-spin text-blue-600" />
      </div>
    );
  }

  return (
    <>
      <Navigation currentPage="packages" />
      
      <div className="min-h-screen bg-gradient-to-br from-gray-50 to-gray-100 py-12 px-4">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-12">
            <h1 className="text-4xl font-bold text-gray-900 mb-4">
              Choose Your Package
            </h1>
            <p className="text-xl text-gray-600 max-w-2xl mx-auto">
              Select the perfect Azure CAF Landing Zone package for your organization
            </p>
          </div>

          <div className="grid md:grid-cols-3 gap-8 mb-8">
            {packages.map((pkg) => {
              const isSelected = selectedTier === pkg.tier;
              const colors = getColorClasses(pkg.color, isSelected);

              return (
                <div
                  key={pkg.tier}
                  onClick={() => setSelectedTier(pkg.tier)}
                  className={`relative rounded-2xl ${colors.bg} ${colors.border} border shadow-lg hover:shadow-xl transition-all cursor-pointer transform hover:scale-105`}
                >
                  {pkg.recommended && (
                    <div className="absolute -top-4 left-1/2 transform -translate-x-1/2">
                      <span className={`${colors.badge} px-4 py-1 rounded-full text-sm font-semibold`}>
                        Recommended
                      </span>
                    </div>
                  )}

                  <div className="p-8">
                    <div className="text-center mb-6">
                      <h3 className="text-2xl font-bold text-gray-900 mb-2">
                        {pkg.name}
                      </h3>
                      <p className="text-gray-600 text-sm mb-4">
                        {pkg.description}
                      </p>
                      <div className="flex items-baseline justify-center">
                        <span className="text-5xl font-bold text-gray-900">
                          ${pkg.monthly_cost.toLocaleString()}
                        </span>
                        <span className="text-gray-600 ml-2">/month</span>
                      </div>
                    </div>

                    <div className="space-y-3 mb-8">
                      {pkg.highlights.map((feature, index) => (
                        <div key={index} className="flex items-start">
                          <Check className="w-5 h-5 text-green-500 mr-3 flex-shrink-0 mt-0.5" />
                          <span className="text-gray-700 text-sm">{feature}</span>
                        </div>
                      ))}
                    </div>

                    <button
                      onClick={() => setSelectedTier(pkg.tier)}
                      className={`w-full py-3 rounded-lg font-semibold transition-colors ${
                        isSelected
                          ? `${colors.button} text-white`
                          : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                      }`}
                    >
                      {isSelected ? 'Selected' : 'Select Package'}
                    </button>
                  </div>
                </div>
              );
            })}
          </div>

          <div className="text-center">
            <button
              onClick={handleContinue}
              disabled={!selectedTier}
              className="inline-flex items-center px-8 py-4 bg-blue-600 text-white font-semibold rounded-lg hover:bg-blue-700 transition-colors disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              Continue to Deployment
              <ArrowRight className="w-5 h-5 ml-2" />
            </button>
          </div>
        </div>
      </div>
    </>
  );
};

export default PackageSelection;
import React from 'react';

const LoadingSkeleton = ({ type = 'card' }) => {
  if (type === 'card') {
    return (
      <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 animate-pulse">
        <div className="flex items-center justify-between mb-4">
          <div className="w-12 h-12 bg-gray-200 rounded-lg"></div>
          <div className="w-16 h-6 bg-gray-200 rounded"></div>
        </div>
        <div className="w-24 h-8 bg-gray-200 rounded mb-2"></div>
        <div className="w-32 h-4 bg-gray-200 rounded"></div>
      </div>
    );
  }

  if (type === 'table-row') {
    return (
      <tr className="animate-pulse">
        <td className="px-6 py-4"><div className="w-32 h-4 bg-gray-200 rounded"></div></td>
        <td className="px-6 py-4"><div className="w-24 h-4 bg-gray-200 rounded"></div></td>
        <td className="px-6 py-4"><div className="w-20 h-4 bg-gray-200 rounded"></div></td>
        <td className="px-6 py-4"><div className="w-16 h-6 bg-gray-200 rounded-full"></div></td>
        <td className="px-6 py-4"><div className="w-20 h-4 bg-gray-200 rounded"></div></td>
        <td className="px-6 py-4"><div className="w-8 h-4 bg-gray-200 rounded"></div></td>
      </tr>
    );
  }

  if (type === 'chart') {
    return (
      <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 animate-pulse">
        <div className="w-48 h-6 bg-gray-200 rounded mb-4"></div>
        <div className="space-y-3">
          <div className="flex items-center space-x-3">
            <div className="w-full h-8 bg-gray-200 rounded"></div>
          </div>
          <div className="flex items-center space-x-3">
            <div className="w-5/6 h-8 bg-gray-200 rounded"></div>
          </div>
          <div className="flex items-center space-x-3">
            <div className="w-4/6 h-8 bg-gray-200 rounded"></div>
          </div>
          <div className="flex items-center space-x-3">
            <div className="w-3/6 h-8 bg-gray-200 rounded"></div>
          </div>
        </div>
      </div>
    );
  }

  if (type === 'page') {
    return (
      <div className="max-w-7xl mx-auto px-4 py-8">
        <div className="animate-pulse space-y-8">
          {/* Header */}
          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <div className="w-64 h-8 bg-gray-200 rounded mb-4"></div>
            <div className="w-96 h-4 bg-gray-200 rounded"></div>
          </div>

          {/* Stats Grid */}
          <div className="grid grid-cols-4 gap-6">
            {[1, 2, 3, 4].map(i => (
              <div key={i} className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
                <div className="w-12 h-12 bg-gray-200 rounded-lg mb-4"></div>
                <div className="w-24 h-8 bg-gray-200 rounded mb-2"></div>
                <div className="w-32 h-4 bg-gray-200 rounded"></div>
              </div>
            ))}
          </div>

          {/* Content */}
          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <div className="space-y-4">
              {[1, 2, 3].map(i => (
                <div key={i} className="flex items-center space-x-4">
                  <div className="w-12 h-12 bg-gray-200 rounded-lg"></div>
                  <div className="flex-1">
                    <div className="w-48 h-4 bg-gray-200 rounded mb-2"></div>
                    <div className="w-96 h-3 bg-gray-200 rounded"></div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  // Default skeleton
  return (
    <div className="animate-pulse">
      <div className="w-full h-32 bg-gray-200 rounded"></div>
    </div>
  );
};

export default LoadingSkeleton;
import React from 'react';
import { ArrowLeft, Home, Package, Upload, LayoutDashboard, Shield, FileCheck, Brain, Layers } from 'lucide-react';

const Navigation = ({ currentPage, showBack = true }) => {
  const pages = {
    home: { path: '/', label: 'Home', icon: Home },
    packages: { path: '/packages', label: 'Packages', icon: Package },
    deploy: { path: '/deploy', label: 'Deploy', icon: Upload },
    customer: { path: '/my-infrastructure', label: 'My Dashboard', icon: LayoutDashboard },
    compliance: { path: '/compliance', label: 'Compliance', icon: FileCheck },
    optimizer: { path: '/optimizer', label: 'Optimizer', icon: Brain },
    canvas: { path: '/canvas', label: 'Canvas', icon: Layers },
    admin: { path: '/admin/devops', label: 'Admin', icon: Shield }
  };

  const handleBack = () => {
    window.history.back();
  };

  return (
    <nav className="bg-white border-b border-gray-200 sticky top-0 z-50 shadow-sm">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Left: Back Button */}
          <div className="flex items-center min-w-[100px]">
            {showBack && (
              <button
                onClick={handleBack}
                className="flex items-center text-gray-600 hover:text-gray-900 font-medium transition-colors"
              >
                <ArrowLeft className="w-5 h-5 mr-2" />
                <span className="hidden sm:inline">Back</span>
              </button>
            )}
          </div>

          {/* Center: Logo */}
          <div className="flex items-center">
            <a href="/" className="flex items-center">
              <div className="w-8 h-8 bg-gradient-to-br from-blue-600 to-indigo-600 rounded-lg mr-2"></div>
              <span className="text-xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent whitespace-nowrap">
                Azure CAF-LZ
              </span>
            </a>
          </div>

          {/* Right: Navigation Links */}
          <div className="flex items-center space-x-4 lg:space-x-6 min-w-[100px] justify-end">
            {Object.entries(pages).map(([key, page]) => {
              const Icon = page.icon;
              const isActive = currentPage === key;
              
              return (
                <a
                  key={key}
                  href={page.path}
                  className={`flex items-center space-x-1 lg:space-x-2 font-medium transition-colors text-sm lg:text-base ${isActive ? 'text-blue-600' : 'text-gray-600 hover:text-gray-900'}`}
                >
                  <Icon className="w-4 h-4" />
                  <span className="hidden xl:inline">{page.label}</span>
                </a>
              );
            })}
          </div>
        </div>

        {currentPage && (
          <div className="pb-3 flex items-center text-sm text-gray-600">
            <a href="/" className="hover:text-gray-900">Home</a>
            <span className="mx-2">/</span>
            <span className="text-gray-900 font-medium">{pages[currentPage]?.label}</span>
          </div>
        )}
      </div>
    </nav>
  );
};

export default Navigation;
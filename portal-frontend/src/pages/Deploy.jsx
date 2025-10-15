import React, { useState } from 'react';
import { Cloud, Server, Network, Database, Shield, CheckCircle2, ArrowRight, AlertCircle } from 'lucide-react';
import Navigation from '../components/Navigation';
import DeploymentProgress from '../components/DeploymentProgress';
import Tooltip from '../components/Tooltip';
import { ToastContainer, useToast } from '../components/Toast';

const Deploy = () => {
  const [formData, setFormData] = useState({
    customerName: '',
    email: '',
    companyName: '',
    packageTier: 'standard',
    azureRegion: 'eastus',
    // NEW: Azure Subscription IDs
    managementSubscriptionId: '',
    hubSubscriptionId: '',
    spokeSubscriptionId: '',
    hubVnetCidr: '10.1.0.0/16',
    spokeVnetCidr: '10.2.0.0/16'
  });

  const [errors, setErrors] = useState({});
  const [deploying, setDeploying] = useState(false);
  const [deploymentStarted, setDeploymentStarted] = useState(false);
  const { toasts, addToast, removeToast } = useToast();

  const packages = {
    basic: { name: 'Basic', price: '$1,500/mo', services: 5, color: 'blue' },
    standard: { name: 'Standard', price: '$3,500/mo', services: 12, color: 'indigo' },
    premium: { name: 'Premium', price: '$6,500/mo', services: 17, color: 'purple' }
  };

  const regions = [
    { value: 'eastus', label: 'East US', flag: '🇺🇸' },
    { value: 'westus', label: 'West US', flag: '🇺🇸' },
    { value: 'centralus', label: 'Central US', flag: '🇺🇸' },
    { value: 'northeurope', label: 'North Europe', flag: '🇪🇺' },
    { value: 'westeurope', label: 'West Europe', flag: '🇪🇺' }
  ];

  const validateForm = () => {
    const newErrors = {};

    if (!formData.customerName.trim()) {
      newErrors.customerName = 'Customer name is required';
    }

    if (!formData.email.trim()) {
      newErrors.email = 'Email is required';
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
      newErrors.email = 'Invalid email format';
    }

    if (!formData.companyName.trim()) {
      newErrors.companyName = 'Company name is required';
    }

    // NEW: Subscription ID validation
    const uuidRegex = /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i;
    
    if (!formData.managementSubscriptionId.trim()) {
      newErrors.managementSubscriptionId = 'Management subscription ID is required';
    } else if (!uuidRegex.test(formData.managementSubscriptionId)) {
      newErrors.managementSubscriptionId = 'Invalid subscription ID format';
    }

    if (!formData.hubSubscriptionId.trim()) {
      newErrors.hubSubscriptionId = 'Hub subscription ID is required';
    } else if (!uuidRegex.test(formData.hubSubscriptionId)) {
      newErrors.hubSubscriptionId = 'Invalid subscription ID format';
    }

    if (!formData.spokeSubscriptionId.trim()) {
      newErrors.spokeSubscriptionId = 'Spoke subscription ID is required';
    } else if (!uuidRegex.test(formData.spokeSubscriptionId)) {
      newErrors.spokeSubscriptionId = 'Invalid subscription ID format';
    }

    // CIDR validation
    const cidrRegex = /^(\d{1,3}\.){3}\d{1,3}\/\d{1,2}$/;
    if (!cidrRegex.test(formData.hubVnetCidr)) {
      newErrors.hubVnetCidr = 'Invalid CIDR format (e.g., 10.0.0.0/16)';
    }
    if (!cidrRegex.test(formData.spokeVnetCidr)) {
      newErrors.spokeVnetCidr = 'Invalid CIDR format (e.g., 10.1.0.0/16)';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
    if (errors[name]) {
      setErrors(prev => ({ ...prev, [name]: '' }));
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    if (!validateForm()) {
      addToast('Please fix the form errors before submitting', 'error');
      return;
    }

    setDeploying(true);
    addToast('Initiating deployment...', 'info');

    try {
      // NEW: Updated payload format for backend
      const payload = {
        packageType: formData.packageTier,
        companyName: formData.companyName,
        contactEmail: formData.email,
        azureSubscriptions: {
          management: formData.managementSubscriptionId,
          hub: formData.hubSubscriptionId,
          spoke: formData.spokeSubscriptionId
        },
        networkConfig: {
          hubVnetCidr: formData.hubVnetCidr,
          spokeVnetCidr: formData.spokeVnetCidr
        }
      };

      const response = await fetch('http://localhost:8000/api/deploy', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        throw new Error('Deployment failed');
      }

      const result = await response.json();
      setDeploymentStarted(true);
      addToast('Deployment started successfully!', 'success');
      
      setTimeout(() => {
        window.location.href = '/my-infrastructure';
      }, 3000);
    } catch (error) {
      addToast('Deployment failed. Please try again.', 'error');
      setDeploying(false);
    }
  };

  if (deploymentStarted) {
    return (
      <>
        <Navigation currentPage="deploy" />
        <div className="min-h-screen bg-gray-50 py-20">
          <div className="max-w-4xl mx-auto px-4">
            <DeploymentProgress />
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <Navigation currentPage="deploy" />
      <ToastContainer toasts={toasts} removeToast={removeToast} />
      
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 py-12">
        <div className="max-w-6xl mx-auto px-4">
          <div className="text-center mb-12">
            <div className="inline-flex items-center bg-blue-100 text-blue-700 px-4 py-2 rounded-full text-sm font-semibold mb-4">
              <Cloud className="w-4 h-4 mr-2" />
              Quick Deployment - Ready in 45 Minutes
            </div>
            <h1 className="text-4xl font-bold text-gray-900 mb-4">
              Deploy Azure Infrastructure
            </h1>
            <p className="text-xl text-gray-600">
              Production-ready Cloud Adoption Framework Landing Zone
            </p>
          </div>

          <div className="grid lg:grid-cols-3 gap-8">
            <div className="lg:col-span-2">
              <form onSubmit={handleSubmit} className="bg-white rounded-2xl shadow-xl border border-gray-200 p-8">
                
                {/* Customer Details */}
                <div className="mb-8">
                  <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center">
                    <Server className="w-5 h-5 mr-2 text-blue-600" />
                    Customer Details
                  </h2>
                  <div className="space-y-4">
                    <div>
                      <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
                        Customer Name *
                        <Tooltip content="Primary contact name for this deployment" showIcon />
                      </label>
                      <input
                        type="text"
                        name="customerName"
                        value={formData.customerName}
                        onChange={handleChange}
                        className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 ${
                          errors.customerName ? 'border-red-500' : 'border-gray-300'
                        }`}
                        placeholder="John Doe"
                      />
                      {errors.customerName && (
                        <div className="flex items-center mt-2 text-sm text-red-600">
                          <AlertCircle className="w-4 h-4 mr-1" />
                          {errors.customerName}
                        </div>
                      )}
                    </div>

                    <div>
                      <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
                        Email Address *
                      </label>
                      <input
                        type="email"
                        name="email"
                        value={formData.email}
                        onChange={handleChange}
                        className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 ${
                          errors.email ? 'border-red-500' : 'border-gray-300'
                        }`}
                        placeholder="john@company.com"
                      />
                      {errors.email && (
                        <div className="flex items-center mt-2 text-sm text-red-600">
                          <AlertCircle className="w-4 h-4 mr-1" />
                          {errors.email}
                        </div>
                      )}
                    </div>

                    <div>
                      <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
                        Company Name *
                      </label>
                      <input
                        type="text"
                        name="companyName"
                        value={formData.companyName}
                        onChange={handleChange}
                        className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 ${
                          errors.companyName ? 'border-red-500' : 'border-gray-300'
                        }`}
                        placeholder="Acme Corp"
                      />
                      {errors.companyName && (
                        <div className="flex items-center mt-2 text-sm text-red-600">
                          <AlertCircle className="w-4 h-4 mr-1" />
                          {errors.companyName}
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* NEW: Azure Subscriptions Section */}
                <div className="mb-8">
                  <h2 className="text-xl font-bold text-gray-900 mb-2 flex items-center">
                    <Cloud className="w-5 h-5 mr-2 text-blue-600" />
                    Azure Subscriptions
                  </h2>
                  <p className="text-sm text-gray-600 mb-4">
                    You can use the same subscription ID for all three (recommended for demo)
                  </p>
                  <div className="space-y-4">
                    <div>
                      <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
                        Management Subscription ID *
                        <Tooltip content="Subscription for logging and management resources" showIcon />
                      </label>
                      <input
                        type="text"
                        name="managementSubscriptionId"
                        value={formData.managementSubscriptionId}
                        onChange={handleChange}
                        className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 font-mono text-sm ${
                          errors.managementSubscriptionId ? 'border-red-500' : 'border-gray-300'
                        }`}
                        placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
                      />
                      {errors.managementSubscriptionId && (
                        <div className="flex items-center mt-2 text-sm text-red-600">
                          <AlertCircle className="w-4 h-4 mr-1" />
                          {errors.managementSubscriptionId}
                        </div>
                      )}
                    </div>

                    <div>
                      <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
                        Hub Subscription ID *
                        <Tooltip content="Subscription for hub network and firewall" showIcon />
                      </label>
                      <input
                        type="text"
                        name="hubSubscriptionId"
                        value={formData.hubSubscriptionId}
                        onChange={handleChange}
                        className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 font-mono text-sm ${
                          errors.hubSubscriptionId ? 'border-red-500' : 'border-gray-300'
                        }`}
                        placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
                      />
                      {errors.hubSubscriptionId && (
                        <div className="flex items-center mt-2 text-sm text-red-600">
                          <AlertCircle className="w-4 h-4 mr-1" />
                          {errors.hubSubscriptionId}
                        </div>
                      )}
                    </div>

                    <div>
                      <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
                        Spoke Subscription ID *
                        <Tooltip content="Subscription for production workloads" showIcon />
                      </label>
                      <input
                        type="text"
                        name="spokeSubscriptionId"
                        value={formData.spokeSubscriptionId}
                        onChange={handleChange}
                        className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 font-mono text-sm ${
                          errors.spokeSubscriptionId ? 'border-red-500' : 'border-gray-300'
                        }`}
                        placeholder="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
                      />
                      {errors.spokeSubscriptionId && (
                        <div className="flex items-center mt-2 text-sm text-red-600">
                          <AlertCircle className="w-4 h-4 mr-1" />
                          {errors.spokeSubscriptionId}
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Infrastructure Configuration */}
                <div className="mb-8">
                  <h2 className="text-xl font-bold text-gray-900 mb-4 flex items-center">
                    <Network className="w-5 h-5 mr-2 text-blue-600" />
                    Infrastructure Configuration
                  </h2>
                  <div className="space-y-4">
                    <div>
                      <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
                        Package Tier *
                        <Tooltip content="Select the package that matches your requirements" showIcon />
                      </label>
                      <div className="grid grid-cols-3 gap-4">
                        {Object.entries(packages).map(([key, pkg]) => (
                          <button
                            key={key}
                            type="button"
                            onClick={() => setFormData(prev => ({ ...prev, packageTier: key }))}
                            className={`p-4 rounded-lg border-2 transition-all ${
                              formData.packageTier === key
                                ? 'border-blue-500 bg-blue-50'
                                : 'border-gray-200 hover:border-gray-300'
                            }`}
                          >
                            <div className="font-semibold text-gray-900 mb-1">{pkg.name}</div>
                            <div className="text-sm text-gray-600 mb-2">{pkg.price}</div>
                            <div className="text-xs text-gray-500">{pkg.services} services</div>
                          </button>
                        ))}
                      </div>
                    </div>

                    <div>
                      <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
                        Azure Region *
                        <Tooltip content="Primary region for your infrastructure deployment" showIcon />
                      </label>
                      <select
                        name="azureRegion"
                        value={formData.azureRegion}
                        onChange={handleChange}
                        className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                      >
                        {regions.map(region => (
                          <option key={region.value} value={region.value}>
                            {region.flag} {region.label}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
                          Hub VNet CIDR *
                          <Tooltip content="CIDR block for Hub virtual network" showIcon />
                        </label>
                        <input
                          type="text"
                          name="hubVnetCidr"
                          value={formData.hubVnetCidr}
                          onChange={handleChange}
                          className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 font-mono text-sm ${
                            errors.hubVnetCidr ? 'border-red-500' : 'border-gray-300'
                          }`}
                          placeholder="10.1.0.0/16"
                        />
                        {errors.hubVnetCidr && (
                          <div className="flex items-center mt-2 text-sm text-red-600">
                            <AlertCircle className="w-4 h-4 mr-1" />
                            {errors.hubVnetCidr}
                          </div>
                        )}
                      </div>

                      <div>
                        <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
                          Spoke VNet CIDR *
                          <Tooltip content="CIDR block for Spoke virtual network" showIcon />
                        </label>
                        <input
                          type="text"
                          name="spokeVnetCidr"
                          value={formData.spokeVnetCidr}
                          onChange={handleChange}
                          className={`w-full px-4 py-3 border rounded-lg focus:ring-2 focus:ring-blue-500 font-mono text-sm ${
                            errors.spokeVnetCidr ? 'border-red-500' : 'border-gray-300'
                          }`}
                          placeholder="10.2.0.0/16"
                        />
                        {errors.spokeVnetCidr && (
                          <div className="flex items-center mt-2 text-sm text-red-600">
                            <AlertCircle className="w-4 h-4 mr-1" />
                            {errors.spokeVnetCidr}
                          </div>
                        )}
                      </div>
                    </div>
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={deploying}
                  className="w-full bg-gradient-to-r from-blue-600 to-indigo-600 text-white py-4 rounded-xl font-bold text-lg hover:shadow-2xl hover:scale-105 transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center space-x-2"
                >
                  {deploying ? (
                    <>
                      <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin"></div>
                      <span>Deploying...</span>
                    </>
                  ) : (
                    <>
                      <span>Deploy Infrastructure</span>
                      <ArrowRight className="w-5 h-5" />
                    </>
                  )}
                </button>
              </form>
            </div>

            {/* Summary Sidebar */}
            <div className="lg:col-span-1">
              <div className="bg-white rounded-2xl shadow-xl border border-gray-200 p-6 sticky top-4">
                <h3 className="text-lg font-bold text-gray-900 mb-4">Deployment Summary</h3>
                
                <div className="space-y-4 mb-6">
                  <div className="flex items-center space-x-3 text-sm">
                    <Shield className="w-5 h-5 text-blue-600 flex-shrink-0" />
                    <span className="text-gray-700">Enterprise Security Built-in</span>
                  </div>
                  <div className="flex items-center space-x-3 text-sm">
                    <CheckCircle2 className="w-5 h-5 text-green-600 flex-shrink-0" />
                    <span className="text-gray-700">SOC2, HIPAA, ISO 27001 Compliant</span>
                  </div>
                  <div className="flex items-center space-x-3 text-sm">
                    <Database className="w-5 h-5 text-purple-600 flex-shrink-0" />
                    <span className="text-gray-700">{packages[formData.packageTier].services} Azure Services</span>
                  </div>
                  <div className="flex items-center space-x-3 text-sm">
                    <Network className="w-5 h-5 text-indigo-600 flex-shrink-0" />
                    <span className="text-gray-700">3-Subscription Architecture</span>
                  </div>
                </div>

                <div className="border-t pt-4 mb-4">
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm text-gray-600">Selected Package</span>
                    <span className="font-semibold text-gray-900">{packages[formData.packageTier].name}</span>
                  </div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-sm text-gray-600">Monthly Cost</span>
                    <span className="font-semibold text-gray-900">{packages[formData.packageTier].price}</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-sm text-gray-600">Deployment Time</span>
                    <span className="font-semibold text-gray-900">~45 minutes</span>
                  </div>
                </div>

                <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                  <div className="text-sm font-semibold text-green-900 mb-1">✓ Production Ready</div>
                  <div className="text-xs text-green-700">
                    Your infrastructure will be fully configured and ready for production workloads
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default Deploy;
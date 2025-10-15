import React, { useState } from 'react';
import { 
  Server, 
  Database, 
  Network,
  Shield,
  HardDrive,
  Cloud,
  Lock,
  Activity,
  Zap,
  FileText,
  Search
} from 'lucide-react';

const ServicePalette = ({ onAddService }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');

  const categories = [
    { id: 'all', name: 'All Services' },
    { id: 'compute', name: 'Compute' },
    { id: 'networking', name: 'Networking' },
    { id: 'storage', name: 'Storage' },
    { id: 'security', name: 'Security' }
  ];

  const services = [
    {
      type: 'virtual_machine',
      name: 'Virtual Machine',
      category: 'compute',
      icon: Server,
      color: 'blue',
      monthlyCost: 145.50,
      description: 'Scalable compute capacity'
    },
    {
      type: 'app_service',
      name: 'App Service',
      category: 'compute',
      icon: Cloud,
      color: 'indigo',
      monthlyCost: 75.00,
      description: 'Web app hosting'
    },
    {
      type: 'virtual_network',
      name: 'Virtual Network',
      category: 'networking',
      icon: Network,
      color: 'green',
      monthlyCost: 15.00,
      description: 'Isolated network'
    },
    {
      type: 'firewall',
      name: 'Azure Firewall',
      category: 'networking',
      icon: Shield,
      color: 'red',
      monthlyCost: 650.00,
      description: 'Network security'
    },
    {
      type: 'storage_account',
      name: 'Storage Account',
      category: 'storage',
      icon: HardDrive,
      color: 'yellow',
      monthlyCost: 23.50,
      description: 'Blob, file, queue storage'
    },
    {
      type: 'sql_database',
      name: 'SQL Database',
      category: 'storage',
      icon: Database,
      color: 'purple',
      monthlyCost: 350.00,
      description: 'Managed SQL database'
    },
    {
      type: 'key_vault',
      name: 'Key Vault',
      category: 'security',
      icon: Lock,
      color: 'orange',
      monthlyCost: 8.00,
      description: 'Secrets management'
    },
    {
      type: 'log_analytics',
      name: 'Log Analytics',
      category: 'security',
      icon: Activity,
      color: 'teal',
      monthlyCost: 45.00,
      description: 'Monitoring and logs'
    },
    {
      type: 'application_gateway',
      name: 'App Gateway',
      category: 'networking',
      icon: Zap,
      color: 'pink',
      monthlyCost: 180.00,
      description: 'Load balancer'
    },
    {
      type: 'cosmos_db',
      name: 'Cosmos DB',
      category: 'storage',
      icon: Database,
      color: 'cyan',
      monthlyCost: 450.00,
      description: 'NoSQL database'
    }
  ];

  const filteredServices = services.filter(service => {
    const matchesSearch = service.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         service.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || service.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  return (
    <div className="h-full flex flex-col">
      <div className="p-4 border-b border-gray-200">
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Azure Services</h3>
        
        {/* Search */}
        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            type="text"
            placeholder="Search services..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
          />
        </div>

        {/* Category Tabs */}
        <div className="flex flex-wrap gap-2">
          {categories.map(category => (
            <button
              key={category.id}
              onClick={() => setSelectedCategory(category.id)}
              className={`px-3 py-1 text-xs font-medium rounded-full transition-colors ${
                selectedCategory === category.id
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              {category.name}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-4 space-y-2">
        {filteredServices.map(service => {
          const Icon = service.icon;
          return (
            <button
              key={service.type}
              onClick={() => onAddService(service)}
              className="w-full bg-white border border-gray-200 rounded-lg p-3 hover:border-blue-500 hover:shadow-md transition-all text-left group"
            >
              <div className="flex items-start space-x-3">
                <div className={`p-2 rounded-lg bg-${service.color}-100 group-hover:bg-${service.color}-200 transition-colors`}>
                  <Icon className={`w-5 h-5 text-${service.color}-600`} />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="font-semibold text-gray-900 text-sm mb-1">{service.name}</div>
                  <div className="text-xs text-gray-600 mb-2">{service.description}</div>
                  <div className="text-xs font-semibold text-gray-900">
                    ${service.monthlyCost}/mo
                  </div>
                </div>
              </div>
            </button>
          );
        })}

        {filteredServices.length === 0 && (
          <div className="text-center py-8 text-gray-500">
            <FileText className="w-12 h-12 mx-auto mb-2 text-gray-300" />
            <p>No services found</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ServicePalette;
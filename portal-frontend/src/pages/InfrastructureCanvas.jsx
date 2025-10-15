import React, { useState } from 'react';
import { 
  Layers, 
  Download,
  Code,
  DollarSign,
  Save,
  Trash2,
  Eye
} from 'lucide-react';
import Navigation from '../components/Navigation';
import ServicePalette from '../components/ServicePalette';
import Canvas from '../components/Canvas';
import CostEstimator from '../components/CostEstimator';

const InfrastructureCanvas = () => {
  const [canvasItems, setCanvasItems] = useState([]);
  const [selectedItem, setSelectedItem] = useState(null);
  const [showCode, setShowCode] = useState(false);

  const addToCanvas = (service) => {
    const newItem = {
      id: `${service.type}-${Date.now()}`,
      type: service.type,
      name: service.name,
      icon: service.icon,
      position: { x: 100, y: 100 },
      config: service.defaultConfig || {}
    };
    setCanvasItems([...canvasItems, newItem]);
  };

  const removeFromCanvas = (itemId) => {
    setCanvasItems(canvasItems.filter(item => item.id !== itemId));
    if (selectedItem?.id === itemId) setSelectedItem(null);
  };

  const updateItemPosition = (itemId, position) => {
    setCanvasItems(canvasItems.map(item => 
      item.id === itemId ? { ...item, position } : item
    ));
  };

  const clearCanvas = () => {
    if (window.confirm('Clear entire canvas?')) {
      setCanvasItems([]);
      setSelectedItem(null);
    }
  };

  const exportDiagram = () => {
    alert('Exporting infrastructure diagram as PNG...');
  };

  const generateTerraform = () => {
    setShowCode(true);
  };

  return (
    <>
      <Navigation currentPage="canvas" />
      
      <div className="min-h-screen bg-gray-50">
        <div className="bg-gradient-to-r from-indigo-600 to-blue-600 text-white">
          <div className="max-w-7xl mx-auto px-4 py-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <Layers className="w-8 h-8" />
                <div>
                  <h1 className="text-3xl font-bold">Visual Infrastructure Designer</h1>
                  <p className="text-indigo-100 mt-1">Drag, drop, and deploy Azure infrastructure</p>
                </div>
              </div>
              <div className="flex items-center space-x-3">
                <button 
                  onClick={clearCanvas}
                  className="flex items-center space-x-2 bg-red-500/20 hover:bg-red-500/30 text-white px-4 py-2 rounded-lg transition-colors"
                >
                  <Trash2 className="w-4 h-4" />
                  <span>Clear</span>
                </button>
                <button 
                  onClick={exportDiagram}
                  className="flex items-center space-x-2 bg-white/20 hover:bg-white/30 text-white px-4 py-2 rounded-lg transition-colors"
                >
                  <Download className="w-4 h-4" />
                  <span>Export</span>
                </button>
                <button 
                  onClick={generateTerraform}
                  className="flex items-center space-x-2 bg-white text-indigo-600 px-4 py-2 rounded-lg hover:bg-indigo-50 transition-colors font-semibold"
                >
                  <Code className="w-4 h-4" />
                  <span>Generate Code</span>
                </button>
              </div>
            </div>
          </div>
        </div>

        <div className="flex h-[calc(100vh-200px)]">
          {/* Left Sidebar - Service Palette */}
          <div className="w-80 bg-white border-r border-gray-200 overflow-y-auto">
            <ServicePalette onAddService={addToCanvas} />
          </div>

          {/* Center - Canvas */}
          <div className="flex-1 bg-gray-100 relative overflow-hidden">
            <Canvas 
              items={canvasItems}
              selectedItem={selectedItem}
              onSelectItem={setSelectedItem}
              onUpdatePosition={updateItemPosition}
              onRemoveItem={removeFromCanvas}
            />
            
            {canvasItems.length === 0 && (
              <div className="absolute inset-0 flex items-center justify-center">
                <div className="text-center">
                  <Layers className="w-16 h-16 text-gray-300 mx-auto mb-4" />
                  <h3 className="text-xl font-semibold text-gray-600 mb-2">Start Building</h3>
                  <p className="text-gray-500">Drag services from the palette to design your infrastructure</p>
                </div>
              </div>
            )}
          </div>

          {/* Right Sidebar - Cost Estimator */}
          <div className="w-80 bg-white border-l border-gray-200 overflow-y-auto">
            <CostEstimator items={canvasItems} />
          </div>
        </div>

        {/* Code Preview Modal */}
        {showCode && (
          <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
            <div className="bg-white rounded-xl shadow-2xl max-w-4xl w-full max-h-[80vh] overflow-hidden">
              <div className="p-6 border-b border-gray-200 flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <Code className="w-6 h-6 text-indigo-600" />
                  <h2 className="text-xl font-bold text-gray-900">Generated Terraform Code</h2>
                </div>
                <button 
                  onClick={() => setShowCode(false)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <span className="text-2xl">×</span>
                </button>
              </div>
              <div className="p-6 overflow-y-auto max-h-[60vh]">
                <pre className="bg-gray-900 text-green-400 p-4 rounded-lg overflow-x-auto text-sm font-mono">
{`# Generated Terraform Configuration
# Resources: ${canvasItems.length}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

${canvasItems.map(item => `
resource "azurerm_${item.type}" "${item.id}" {
  name                = "${item.name}"
  location            = "East US"
  resource_group_name = azurerm_resource_group.main.name
  
  # Additional configuration...
}`).join('\n')}
`}
                </pre>
              </div>
              <div className="p-6 border-t border-gray-200 flex justify-end space-x-3">
                <button 
                  onClick={() => setShowCode(false)}
                  className="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
                >
                  Close
                </button>
                <button className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors">
                  Download .tf File
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </>
  );
};

export default InfrastructureCanvas;
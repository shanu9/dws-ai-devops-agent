import React, { useState, useEffect } from 'react';
import { 
  Shield, 
  CheckCircle2, 
  XCircle, 
  AlertTriangle,
  Download,
  RefreshCw,
  FileText,
  Zap,
  Lock,
  Activity
} from 'lucide-react';
import Navigation from '../components/Navigation';
import ComplianceScore from '../components/ComplianceScore';
import PolicyViolations from '../components/PolicyViolations';
import FrameworkSelector from '../components/FrameworkSelector';
import LoadingSkeleton from '../components/LoadingSkeleton';
import EmptyState from '../components/EmptyState';
import Tooltip from '../components/Tooltip';
import { ToastContainer, useToast } from '../components/Toast';

const ComplianceDashboard = () => {
  const [selectedFramework, setSelectedFramework] = useState('SOC2');
  const [loading, setLoading] = useState(false);
  const [scanning, setScanning] = useState(false);
  const { toasts, addToast, removeToast } = useToast();
  
  const [complianceData, setComplianceData] = useState({
    overallScore: 87,
    lastScan: new Date().toISOString(),
    totalPolicies: 156,
    compliant: 136,
    violations: 20,
    frameworks: {
      SOC2: { score: 87, policies: 45, violations: 6 },
      HIPAA: { score: 92, policies: 38, violations: 3 },
      ISO27001: { score: 85, policies: 52, violations: 8 },
      GDPR: { score: 90, policies: 28, violations: 3 },
      PCI_DSS: { score: 88, policies: 32, violations: 4 }
    }
  });

  const frameworks = [
    { id: 'SOC2', name: 'SOC 2', icon: Shield, color: 'blue' },
    { id: 'HIPAA', name: 'HIPAA', icon: Lock, color: 'purple' },
    { id: 'ISO27001', name: 'ISO 27001', icon: FileText, color: 'green' },
    { id: 'GDPR', name: 'GDPR', icon: Activity, color: 'indigo' },
    { id: 'PCI_DSS', name: 'PCI-DSS', icon: Zap, color: 'red' }
  ];

  const runComplianceScan = async () => {
    setScanning(true);
    addToast('Starting compliance scan...', 'info');
    
    try {
      await new Promise(resolve => setTimeout(resolve, 3000));
      setComplianceData({
        ...complianceData,
        lastScan: new Date().toISOString()
      });
      addToast('Compliance scan completed successfully!', 'success');
    } catch (error) {
      addToast('Compliance scan failed. Please try again.', 'error');
    } finally {
      setScanning(false);
    }
  };

  const downloadReport = () => {
    const frameworkName = frameworks.find(f => f.id === selectedFramework).name;
    addToast(`Generating ${frameworkName} compliance report...`, 'info');
    setTimeout(() => {
      addToast('Report downloaded successfully!', 'success');
    }, 1500);
  };

  const currentFramework = complianceData.frameworks[selectedFramework];

  if (loading) {
    return (
      <>
        <Navigation currentPage="compliance" />
        <LoadingSkeleton type="page" />
      </>
    );
  }

  return (
    <>
      <Navigation currentPage="compliance" />
      <ToastContainer toasts={toasts} removeToast={removeToast} />
      
      <div className="min-h-screen bg-gray-50">
        <div className="bg-gradient-to-r from-indigo-600 to-purple-600 text-white">
          <div className="max-w-7xl mx-auto px-4 py-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-3">
                <Shield className="w-8 h-8" />
                <div>
                  <h1 className="text-3xl font-bold">Compliance Dashboard</h1>
                  <p className="text-indigo-100 mt-1">Monitor policy compliance across frameworks</p>
                </div>
              </div>
              <div className="flex items-center space-x-3">
                <Tooltip content="Download compliance report as PDF">
                  <button 
                    onClick={downloadReport}
                    className="flex items-center space-x-2 bg-white/20 hover:bg-white/30 text-white px-4 py-2 rounded-lg transition-colors"
                  >
                    <Download className="w-4 h-4" />
                    <span>Download Report</span>
                  </button>
                </Tooltip>
                <Tooltip content="Run compliance scan across all policies">
                  <button 
                    onClick={runComplianceScan}
                    disabled={scanning}
                    className="flex items-center space-x-2 bg-white text-indigo-600 px-4 py-2 rounded-lg hover:bg-indigo-50 transition-colors disabled:opacity-50 font-semibold"
                  >
                    <RefreshCw className={`w-4 h-4 ${scanning ? 'animate-spin' : ''}`} />
                    <span>{scanning ? 'Scanning...' : 'Run Scan'}</span>
                  </button>
                </Tooltip>
              </div>
            </div>
          </div>
        </div>

        <div className="max-w-7xl mx-auto px-4 py-8">
          {/* Quick Stats */}
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-8">
            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <CheckCircle2 className="w-8 h-8 text-green-600" />
                <Tooltip content="Percentage of policies passing compliance checks">
                  <span className="text-sm text-green-600 font-semibold">
                    {((complianceData.compliant / complianceData.totalPolicies) * 100).toFixed(0)}%
                  </span>
                </Tooltip>
              </div>
              <div className="text-2xl font-bold text-gray-900">{complianceData.compliant}</div>
              <div className="text-sm text-gray-600">Compliant Policies</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <XCircle className="w-8 h-8 text-red-600" />
                <span className="text-sm text-red-600 font-semibold">{complianceData.violations} Issues</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">{complianceData.violations}</div>
              <div className="text-sm text-gray-600">Policy Violations</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <Shield className="w-8 h-8 text-blue-600" />
                <Tooltip content="Monitoring 5 compliance frameworks">
                  <span className="text-sm text-blue-600 font-semibold">5 Active</span>
                </Tooltip>
              </div>
              <div className="text-2xl font-bold text-gray-900">{complianceData.totalPolicies}</div>
              <div className="text-sm text-gray-600">Total Policies</div>
            </div>

            <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-4">
                <Activity className="w-8 h-8 text-purple-600" />
                <span className="text-sm text-gray-600 font-semibold">Live</span>
              </div>
              <div className="text-2xl font-bold text-gray-900">{complianceData.overallScore}%</div>
              <div className="text-sm text-gray-600">Overall Score</div>
            </div>
          </div>

          {/* Framework Selector */}
          <FrameworkSelector 
            frameworks={frameworks}
            selected={selectedFramework}
            onChange={(framework) => {
              setSelectedFramework(framework);
              addToast(`Switched to ${frameworks.find(f => f.id === framework).name}`, 'info');
            }}
            data={complianceData.frameworks}
          />

          {/* Score & Violations */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
            <div className="lg:col-span-1">
              <ComplianceScore 
                score={currentFramework.score}
                framework={frameworks.find(f => f.id === selectedFramework).name}
                lastScan={complianceData.lastScan}
              />
            </div>
            
            <div className="lg:col-span-2">
              {currentFramework.violations > 0 ? (
                <PolicyViolations 
                  framework={selectedFramework}
                  violations={currentFramework.violations}
                />
              ) : (
                <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-12">
                  <EmptyState 
                    type="violations"
                    description={`Your infrastructure is fully compliant with ${frameworks.find(f => f.id === selectedFramework).name} requirements`}
                  />
                </div>
              )}
            </div>
          </div>

          {/* Last Scan Info */}
          <div className="bg-gradient-to-br from-green-500 to-green-600 rounded-3xl p-6 text-white hover:shadow-xl transition-shadow">
            <div className="flex items-center justify-between">
              <div className="flex items-center space-x-4">
                <div className="bg-white/20 p-3 rounded-xl">
                  <CheckCircle2 className="w-8 h-8" />
                </div>
                <div>
                  <div className="text-xl font-bold mb-1">
                    Last Scan: {new Date(complianceData.lastScan).toLocaleString()}
                  </div>
                  <div className="text-green-100 flex items-center space-x-2">
                    <span>Next scheduled scan: Tomorrow at 2:00 AM</span>
                    <Tooltip content="Automatic daily scans ensure continuous compliance">
                      <span className="cursor-help">ⓘ</span>
                    </Tooltip>
                  </div>
                </div>
              </div>
              <button 
                onClick={runComplianceScan}
                disabled={scanning}
                className="bg-white/20 hover:bg-white/30 text-white px-6 py-3 rounded-lg font-semibold transition-colors disabled:opacity-50"
              >
                Run Now
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default ComplianceDashboard;
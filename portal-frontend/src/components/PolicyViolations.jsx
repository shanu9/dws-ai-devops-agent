import React from 'react';
import { AlertTriangle, XCircle, CheckCircle2, Zap } from 'lucide-react';

const PolicyViolations = ({ framework, violations }) => {
  const mockViolations = [
    { id: 1, severity: 'high', policy: 'Encryption at Rest', description: 'Storage account does not have encryption enabled', resource: 'prod-storage-01', autoFix: true },
    { id: 2, severity: 'medium', policy: 'Network Security Groups', description: 'NSG allows unrestricted access on port 22', resource: 'nsg-prod-subnet', autoFix: true },
    { id: 3, severity: 'high', policy: 'Multi-Factor Authentication', description: 'MFA not enabled for admin accounts', resource: 'admin@company.com', autoFix: false },
    { id: 4, severity: 'low', policy: 'Backup Policy', description: 'VM backup not configured according to policy', resource: 'vm-prod-web-01', autoFix: true },
    { id: 5, severity: 'medium', policy: 'Diagnostic Logging', description: 'Diagnostic settings not configured for Key Vault', resource: 'kv-prod-secrets', autoFix: true }
  ];

  const getSeverityColor = (severity) => {
    if (severity === 'high') return 'text-red-600 bg-red-100';
    if (severity === 'medium') return 'text-yellow-600 bg-yellow-100';
    return 'text-blue-600 bg-blue-100';
  };

  const getSeverityIcon = (severity) => {
    if (severity === 'high') return <XCircle className="w-5 h-5" />;
    if (severity === 'medium') return <AlertTriangle className="w-5 h-5" />;
    return <CheckCircle2 className="w-5 h-5" />;
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-lg font-semibold text-gray-900">Policy Violations</h3>
            <p className="text-sm text-gray-600 mt-1">{violations} issues require attention</p>
          </div>
          <div className="flex items-center space-x-2">
            <span className="px-3 py-1 text-xs font-semibold rounded-full bg-red-100 text-red-600">2 High</span>
            <span className="px-3 py-1 text-xs font-semibold rounded-full bg-yellow-100 text-yellow-600">2 Medium</span>
            <span className="px-3 py-1 text-xs font-semibold rounded-full bg-blue-100 text-blue-600">1 Low</span>
          </div>
        </div>
      </div>

      <div className="divide-y divide-gray-200 max-h-96 overflow-y-auto">
        {mockViolations.map((violation) => (
          <div key={violation.id} className="p-6 hover:bg-gray-50 transition-colors">
            <div className="flex items-start justify-between">
              <div className="flex items-start space-x-4 flex-1">
                <div className={`p-2 rounded-lg ${getSeverityColor(violation.severity)}`}>
                  {getSeverityIcon(violation.severity)}
                </div>
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-2">
                    <h4 className="font-semibold text-gray-900">{violation.policy}</h4>
                    <span className={`px-2 py-1 text-xs font-semibold rounded-full ${getSeverityColor(violation.severity)} uppercase`}>
                      {violation.severity}
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 mb-3">{violation.description}</p>
                  <div className="text-xs text-gray-500">
                    Resource: <span className="font-mono font-semibold text-gray-700">{violation.resource}</span>
                  </div>
                </div>
              </div>
              <div className="ml-4">
                {violation.autoFix ? (
                  <button className="flex items-center space-x-2 bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 transition-colors text-sm font-semibold">
                    <Zap className="w-4 h-4" />
                    <span>Auto-Fix</span>
                  </button>
                ) : (
                  <button className="flex items-center space-x-2 bg-gray-100 text-gray-700 px-4 py-2 rounded-lg hover:bg-gray-200 transition-colors text-sm font-semibold">
                    Manual Review
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default PolicyViolations;
import React from 'react';
import { Cloud, Package, FileText, AlertCircle, Database, Layers } from 'lucide-react';

const EmptyState = ({ 
  type = 'default',
  title,
  description,
  actionLabel,
  onAction,
  icon: CustomIcon
}) => {
  const presets = {
    deployments: {
      icon: Cloud,
      title: 'No Deployments Yet',
      description: 'Get started by deploying your first Azure infrastructure',
      actionLabel: 'Deploy Now',
      iconColor: 'text-blue-600',
      bgColor: 'bg-blue-100'
    },
    resources: {
      icon: Database,
      title: 'No Resources Found',
      description: 'Your infrastructure resources will appear here once deployed',
      actionLabel: 'View Packages',
      iconColor: 'text-green-600',
      bgColor: 'bg-green-100'
    },
    violations: {
      icon: AlertCircle,
      title: 'No Violations Detected',
      description: 'Your infrastructure is fully compliant with all policies',
      actionLabel: 'View Policies',
      iconColor: 'text-green-600',
      bgColor: 'bg-green-100'
    },
    canvas: {
      icon: Layers,
      title: 'Empty Canvas',
      description: 'Start designing your infrastructure by dragging services from the palette',
      actionLabel: null,
      iconColor: 'text-purple-600',
      bgColor: 'bg-purple-100'
    },
    anomalies: {
      icon: AlertCircle,
      title: 'No Anomalies Detected',
      description: 'Your costs are tracking normally with no unusual patterns',
      actionLabel: null,
      iconColor: 'text-green-600',
      bgColor: 'bg-green-100'
    },
    search: {
      icon: FileText,
      title: 'No Results Found',
      description: 'Try adjusting your search or filters',
      actionLabel: 'Clear Filters',
      iconColor: 'text-gray-600',
      bgColor: 'bg-gray-100'
    },
    error: {
      icon: AlertCircle,
      title: 'Something Went Wrong',
      description: 'We couldn\'t load this data. Please try again.',
      actionLabel: 'Retry',
      iconColor: 'text-red-600',
      bgColor: 'bg-red-100'
    }
  };

  const preset = presets[type] || presets.default;
  const Icon = CustomIcon || preset.icon;
  const finalTitle = title || preset.title;
  const finalDescription = description || preset.description;
  const finalActionLabel = actionLabel !== undefined ? actionLabel : preset.actionLabel;

  return (
    <div className="flex flex-col items-center justify-center py-12 px-4 text-center">
      <div className={`w-20 h-20 ${preset.bgColor} rounded-2xl flex items-center justify-center mb-6`}>
        <Icon className={`w-10 h-10 ${preset.iconColor}`} />
      </div>
      <h3 className="text-xl font-semibold text-gray-900 mb-2">
        {finalTitle}
      </h3>
      <p className="text-gray-600 mb-6 max-w-md">
        {finalDescription}
      </p>
      {finalActionLabel && onAction && (
        <button
          onClick={onAction}
          className="bg-blue-600 text-white px-6 py-3 rounded-lg font-semibold hover:bg-blue-700 transition-colors"
        >
          {finalActionLabel}
        </button>
      )}
    </div>
  );
};

export default EmptyState;
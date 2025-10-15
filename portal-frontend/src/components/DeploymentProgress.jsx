import React, { useState, useEffect } from 'react';
import { CheckCircle2, Clock, AlertCircle, Loader2 } from 'lucide-react';

const DeploymentProgress = ({ deploymentId, status, onStatusChange }) => {
  const stages = [
    { id: 1, name: 'Validate & Estimate', duration: 2, icon: CheckCircle2 },
    { id: 2, name: 'Deploy Management', duration: 15, icon: CheckCircle2 },
    { id: 3, name: 'Deploy Hub', duration: 20, icon: Clock },
    { id: 4, name: 'Deploy Spoke', duration: 15, icon: Clock }
  ];

  const [currentStage, setCurrentStage] = useState(1);
  const [progress, setProgress] = useState(0);
  const [timeRemaining, setTimeRemaining] = useState(52);

  useEffect(() => {
    // Simulate progress (replace with real GitHub Actions API)
    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          return 100;
        }
        return prev + 1;
      });
      
      setTimeRemaining(prev => Math.max(0, prev - 0.5));
    }, 300);

    return () => clearInterval(interval);
  }, []);

  const getStageStatus = (stageId) => {
    if (stageId < currentStage) return 'completed';
    if (stageId === currentStage) return 'in_progress';
    return 'pending';
  };

  return (
    <div className="bg-white rounded-xl p-6 shadow-lg border border-gray-200">
      <div className="mb-6">
        <div className="flex items-center justify-between mb-2">
          <h3 className="text-lg font-semibold text-gray-900">
            Deployment Progress
          </h3>
          <span className="text-sm text-gray-600">
            {timeRemaining.toFixed(0)} min remaining
          </span>
        </div>
        
        {/* Progress Bar */}
        <div className="relative w-full h-3 bg-gray-200 rounded-full overflow-hidden">
          <div 
            className="absolute top-0 left-0 h-full bg-gradient-to-r from-blue-500 to-indigo-600 transition-all duration-300 ease-out"
            style={{ width: `${progress}%` }}
          />
        </div>
        <div className="mt-1 text-right text-sm font-medium text-gray-900">
          {progress}%
        </div>
      </div>

      {/* Stages */}
      <div className="space-y-4">
        {stages.map((stage, index) => {
          const stageStatus = getStageStatus(stage.id);
          const Icon = stage.icon;
          
          return (
            <div key={stage.id} className="flex items-start">
              {/* Timeline Line */}
              <div className="flex flex-col items-center mr-4">
                <div className={`w-10 h-10 rounded-full flex items-center justify-center ${
                  stageStatus === 'completed' ? 'bg-green-100' :
                  stageStatus === 'in_progress' ? 'bg-blue-100' :
                  'bg-gray-100'
                }`}>
                  {stageStatus === 'completed' && (
                    <CheckCircle2 className="w-5 h-5 text-green-600" />
                  )}
                  {stageStatus === 'in_progress' && (
                    <Loader2 className="w-5 h-5 text-blue-600 animate-spin" />
                  )}
                  {stageStatus === 'pending' && (
                    <Clock className="w-5 h-5 text-gray-400" />
                  )}
                </div>
                {index < stages.length - 1 && (
                  <div className={`w-0.5 h-12 ${
                    stageStatus === 'completed' ? 'bg-green-300' : 'bg-gray-200'
                  }`} />
                )}
              </div>

              {/* Stage Info */}
              <div className="flex-1 pt-1">
                <div className="flex items-center justify-between">
                  <h4 className={`font-semibold ${
                    stageStatus === 'completed' ? 'text-green-900' :
                    stageStatus === 'in_progress' ? 'text-blue-900' :
                    'text-gray-500'
                  }`}>
                    {stage.name}
                  </h4>
                  <span className="text-sm text-gray-500">
                    ~{stage.duration} min
                  </span>
                </div>
                
                {stageStatus === 'completed' && (
                  <p className="text-sm text-green-600 mt-1">✓ Completed</p>
                )}
                {stageStatus === 'in_progress' && (
                  <p className="text-sm text-blue-600 mt-1">In progress...</p>
                )}
                {stageStatus === 'pending' && (
                  <p className="text-sm text-gray-400 mt-1">Waiting...</p>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default DeploymentProgress;
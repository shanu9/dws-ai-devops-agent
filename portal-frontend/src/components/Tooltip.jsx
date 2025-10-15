import React, { useState } from 'react';
import { HelpCircle } from 'lucide-react';

const Tooltip = ({ 
  children, 
  content, 
  position = 'top',
  showIcon = false 
}) => {
  const [isVisible, setIsVisible] = useState(false);

  const positions = {
    top: 'bottom-full left-1/2 transform -translate-x-1/2 mb-2',
    bottom: 'top-full left-1/2 transform -translate-x-1/2 mt-2',
    left: 'right-full top-1/2 transform -translate-y-1/2 mr-2',
    right: 'left-full top-1/2 transform -translate-y-1/2 ml-2'
  };

  const arrows = {
    top: 'top-full left-1/2 transform -translate-x-1/2 border-l-transparent border-r-transparent border-b-transparent border-t-gray-900',
    bottom: 'bottom-full left-1/2 transform -translate-x-1/2 border-l-transparent border-r-transparent border-t-transparent border-b-gray-900',
    left: 'left-full top-1/2 transform -translate-y-1/2 border-t-transparent border-b-transparent border-r-transparent border-l-gray-900',
    right: 'right-full top-1/2 transform -translate-y-1/2 border-t-transparent border-b-transparent border-l-transparent border-r-gray-900'
  };

  return (
    <div 
      className="relative inline-flex items-center"
      onMouseEnter={() => setIsVisible(true)}
      onMouseLeave={() => setIsVisible(false)}
    >
      {showIcon ? (
        <HelpCircle className="w-4 h-4 text-gray-400 hover:text-gray-600 cursor-help" />
      ) : (
        children
      )}
      
      {isVisible && content && (
        <>
          <div className={`absolute ${positions[position]} z-50 px-3 py-2 bg-gray-900 text-white text-sm rounded-lg whitespace-nowrap shadow-lg transition-opacity duration-200`}>
            {content}
          </div>
          <div className={`absolute ${arrows[position]} w-0 h-0 border-4`}></div>
        </>
      )}
    </div>
  );
};

export default Tooltip;
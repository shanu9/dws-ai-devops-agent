import React, { useRef, useState } from 'react';
import { Trash2, Move } from 'lucide-react';

const Canvas = ({ items, selectedItem, onSelectItem, onUpdatePosition, onRemoveItem }) => {
  const canvasRef = useRef(null);
  const [draggingItem, setDraggingItem] = useState(null);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });

  const handleMouseDown = (e, item) => {
    e.stopPropagation();
    const rect = canvasRef.current.getBoundingClientRect();
    setDragOffset({
      x: e.clientX - rect.left - item.position.x,
      y: e.clientY - rect.top - item.position.y
    });
    setDraggingItem(item);
    onSelectItem(item);
  };

  const handleMouseMove = (e) => {
    if (!draggingItem) return;
    
    const rect = canvasRef.current.getBoundingClientRect();
    const newX = Math.max(0, Math.min(rect.width - 120, e.clientX - rect.left - dragOffset.x));
    const newY = Math.max(0, Math.min(rect.height - 120, e.clientY - rect.top - dragOffset.y));
    
    onUpdatePosition(draggingItem.id, { x: newX, y: newY });
  };

  const handleMouseUp = () => {
    setDraggingItem(null);
  };

  const handleCanvasClick = (e) => {
    if (e.target === canvasRef.current) {
      onSelectItem(null);
    }
  };

  return (
    <div
      ref={canvasRef}
      className="w-full h-full relative cursor-default"
      onMouseMove={handleMouseMove}
      onMouseUp={handleMouseUp}
      onMouseLeave={handleMouseUp}
      onClick={handleCanvasClick}
      style={{
        backgroundImage: `
          linear-gradient(rgba(0, 0, 0, 0.05) 1px, transparent 1px),
          linear-gradient(90deg, rgba(0, 0, 0, 0.05) 1px, transparent 1px)
        `,
        backgroundSize: '20px 20px'
      }}
    >
      {items.map(item => {
        const Icon = item.icon;
        const isSelected = selectedItem?.id === item.id;
        
        return (
          <div
            key={item.id}
            className={`absolute cursor-move select-none transition-shadow ${
              isSelected ? 'ring-4 ring-blue-500' : ''
            }`}
            style={{
              left: `${item.position.x}px`,
              top: `${item.position.y}px`,
              width: '120px'
            }}
            onMouseDown={(e) => handleMouseDown(e, item)}
            onClick={(e) => {
              e.stopPropagation();
              onSelectItem(item);
            }}
          >
            <div className={`bg-white rounded-xl shadow-lg border-2 p-4 ${
              isSelected ? 'border-blue-500' : 'border-gray-200'
            } hover:shadow-xl transition-all`}>
              <div className="flex items-center justify-between mb-2">
                <Icon className="w-6 h-6 text-blue-600" />
                {isSelected && (
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      onRemoveItem(item.id);
                    }}
                    className="text-red-500 hover:text-red-700 transition-colors"
                    title="Remove"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
              <div className="text-sm font-semibold text-gray-900 truncate">
                {item.name}
              </div>
              <div className="text-xs text-gray-500 mt-1">
                {item.type}
              </div>
            </div>

            {/* Drag indicator */}
            {isSelected && (
              <div className="absolute -top-8 left-1/2 transform -translate-x-1/2 bg-blue-600 text-white px-2 py-1 rounded text-xs font-semibold whitespace-nowrap flex items-center space-x-1">
                <Move className="w-3 h-3" />
                <span>Drag to move</span>
              </div>
            )}

            {/* Connection points */}
            {isSelected && (
              <>
                <div className="absolute top-0 left-1/2 transform -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-blue-500 rounded-full border-2 border-white"></div>
                <div className="absolute bottom-0 left-1/2 transform -translate-x-1/2 translate-y-1/2 w-3 h-3 bg-blue-500 rounded-full border-2 border-white"></div>
                <div className="absolute left-0 top-1/2 transform -translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-blue-500 rounded-full border-2 border-white"></div>
                <div className="absolute right-0 top-1/2 transform translate-x-1/2 -translate-y-1/2 w-3 h-3 bg-blue-500 rounded-full border-2 border-white"></div>
              </>
            )}
          </div>
        );
      })}
    </div>
  );
};

export default Canvas;
import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Home from './pages/Home';
import Packages from './pages/Packages';
import Deploy from './pages/Deploy';
import AdminDashboard from './pages/AdminDashboard';
import CustomerDashboard from './pages/CustomerDashboard';
import ComplianceDashboard from './pages/ComplianceDashboard';
import CostOptimizer from './pages/CostOptimizer';
import InfrastructureCanvas from './pages/InfrastructureCanvas';
const ProtectedRoute = ({ children }) => {
  const token = localStorage.getItem('token');
  return token ? children : <Navigate to="/login" />;
};

function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/login" element={<Login />} />
        <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
        <Route path="/packages" element={<Packages />} />
        <Route path="/deploy" element={<Deploy />} />
        <Route path="/compliance" element={<ComplianceDashboard />} />
        <Route path="/optimizer" element={<CostOptimizer />} />
        <Route path="/canvas" element={<InfrastructureCanvas />} />
        
        {/* Admin Dashboard - For platform operators */}
        <Route path="/admin/devops" element={<AdminDashboard />} />
        
        {/* Customer Dashboard - For individual customers */}
        <Route path="/my-infrastructure" element={<CustomerDashboard />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
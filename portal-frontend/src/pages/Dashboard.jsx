import React, { useEffect, useState } from 'react';
import { customersAPI } from '../services/api';
import { useNavigate } from 'react-router-dom';

function Dashboard() {
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    customersAPI.list()
      .then(res => setCustomers(res.data))
      .catch(err => console.error(err))
      .finally(() => setLoading(false));
  }, []);

  const handleLogout = () => {
    localStorage.removeItem('token');
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 py-4 flex justify-between">
          <h1 className="text-2xl font-bold">Dashboard</h1>
          <button onClick={handleLogout} className="btn-secondary">Logout</button>
        </div>
      </header>
      <main className="max-w-7xl mx-auto px-4 py-8">
        <div className="grid grid-cols-3 gap-6 mb-8">
          <div className="card"><h3 className="text-gray-500">Customers</h3><p className="text-3xl font-bold">{customers.length}</p></div>
          <div className="card"><h3 className="text-gray-500">Active</h3><p className="text-3xl font-bold text-green-600">{customers.filter(c => c.status === 'active').length}</p></div>
          <div className="card"><h3 className="text-gray-500">Cost</h3><p className="text-3xl font-bold text-blue-600">$125K</p></div>
        </div>
        <div className="card">
          <h2 className="text-xl font-bold mb-4">Customers</h2>
          {loading ? <p>Loading...</p> : customers.length === 0 ? <p>No customers</p> : (
            <table className="w-full">
              <thead><tr className="border-b"><th className="text-left p-3">ID</th><th className="text-left p-3">Name</th><th className="text-left p-3">Status</th></tr></thead>
              <tbody>{customers.map(c => <tr key={c.id} className="border-b"><td className="p-3">{c.id}</td><td className="p-3">{c.name}</td><td className="p-3"><span className="bg-green-100 text-green-800 px-2 py-1 rounded">{c.status}</span></td></tr>)}</tbody>
            </table>
          )}
        </div>
      </main>
    </div>
  );
}

export default Dashboard;
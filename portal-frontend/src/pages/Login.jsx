import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { authAPI } from '../services/api';

function Login() {
  const [username, setUsername] = useState('admin');
  const [password, setPassword] = useState('admin');
  const [error, setError] = useState('');
  const navigate = useNavigate();

  const handleLogin = async (e) => {
    e.preventDefault();
    try {
      const res = await authAPI.login(username, password);
      localStorage.setItem('token', res.data.access_token);
      navigate('/dashboard');
    } catch (err) {
      setError('Login failed');
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-blue-500">
      <div className="bg-white p-8 rounded-xl shadow-2xl w-96">
        <h1 className="text-3xl font-bold mb-6 text-center">Azure CAF-LZ Portal</h1>
        {error && <div className="bg-red-100 text-red-700 p-3 rounded mb-4">{error}</div>}
        <form onSubmit={handleLogin}>
          <div className="mb-4">
            <label className="label">Username</label>
            <input className="input" value={username} onChange={e => setUsername(e.target.value)} />
          </div>
          <div className="mb-4">
            <label className="label">Password</label>
            <input type="password" className="input" value={password} onChange={e => setPassword(e.target.value)} />
          </div>
          <button className="btn-primary w-full">Login</button>
        </form>
      </div>
    </div>
  );
}

export default Login;
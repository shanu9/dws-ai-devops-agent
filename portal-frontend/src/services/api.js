import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api/v1';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor (add auth token)
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor (handle errors)
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// API Methods
export const authAPI = {
  login: (username, password) => 
    api.post('/auth/token', new URLSearchParams({ username, password }), {
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' }
    }),
  
  getMe: () => api.get('/auth/me'),
};

export const customersAPI = {
  list: (params) => api.get('/customers', { params }),
  get: (id) => api.get(`/customers/${id}`),
  create: (data) => api.post('/customers', data),
  update: (id, data) => api.patch(`/customers/${id}`, data),
  delete: (id) => api.delete(`/customers/${id}`),
  getConfig: (id) => api.get(`/customers/${id}/config`),
};

export const deploymentsAPI = {
  list: (customerId) => api.get(`/deploy/customer/${customerId}`),
  get: (id) => api.get(`/deploy/${id}`),
  create: (data) => api.post('/deploy', data),
  approve: (id) => api.post(`/deploy/${id}/approve`),
  getLogs: (id) => api.get(`/deploy/${id}/logs`),
};

export const costAPI = {
  getSummary: (customerId, days = 30) => 
    api.get(`/cost/${customerId}/summary`, { params: { days } }),
  
  getBreakdown: (customerId, days = 30) => 
    api.get(`/cost/${customerId}/breakdown`, { params: { days } }),
  
  getForecast: (customerId, days = 30) => 
    api.get(`/cost/${customerId}/forecast`, { params: { days } }),
  
  getRecommendations: (customerId) => 
    api.get(`/cost/${customerId}/recommendations`),
  
  getTrends: (customerId, months = 6) => 
    api.get(`/cost/${customerId}/trends`, { params: { months } }),
};

export const recommendationsAPI = {
  list: (customerId, category) => 
    api.get(`/recommendations/${customerId}`, { params: { category } }),
  
  apply: (customerId, recommendationId) => 
    api.post(`/recommendations/${customerId}/${recommendationId}/apply`),
};

export default api;
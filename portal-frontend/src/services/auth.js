export const AuthService = {
  login: (token) => {
    localStorage.setItem('token', token);
  },
  
  logout: () => {
    localStorage.removeItem('token');
    window.location.href = '/login';
  },
  
  getToken: () => {
    return localStorage.getItem('token');
  },
  
  isAuthenticated: () => {
    return !!localStorage.getItem('token');
  },
};
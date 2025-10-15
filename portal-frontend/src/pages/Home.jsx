import React, { useState, useEffect } from 'react';
import { Shield, Zap, Lock, TrendingUp, Users, CheckCircle2, ArrowRight, Award, Cloud, Server } from 'lucide-react';
import Navigation from '../components/Navigation';

const Home = () => {
  const [stats, setStats] = useState({
    customers: 0,
    deployments: 0,
    uptime: 0,
    savings: 0
  });

  useEffect(() => {
    const interval = setInterval(() => {
      setStats(prev => ({
        customers: Math.min(prev.customers + 1, 250),
        deployments: Math.min(prev.deployments + 5, 1200),
        uptime: Math.min(prev.uptime + 0.1, 99.9),
        savings: Math.min(prev.savings + 1000, 2500000)
      }));
    }, 20);
    return () => clearInterval(interval);
  }, []);

  const features = [
    {
      icon: Shield,
      title: 'Enterprise Security',
      description: 'SOC 2 Type II certified with Microsoft Defender integration',
      color: 'blue'
    },
    {
      icon: Zap,
      title: 'Deploy in Minutes',
      description: 'One-click deployment saves 80+ hours of manual setup',
      color: 'yellow'
    },
    {
      icon: TrendingUp,
      title: 'Cost Optimized',
      description: 'AI-powered cost optimization saves average 35% on Azure spend',
      color: 'green'
    },
    {
      icon: Lock,
      title: 'Compliance Ready',
      description: 'Pre-configured for HIPAA, GDPR, PCI-DSS compliance',
      color: 'purple'
    }
  ];

  const partners = [
    { name: 'Microsoft', logo: '🔷' },
    { name: 'Azure', logo: '☁️' },
    { name: 'Terraform', logo: '⚡' },
    { name: 'GitHub', logo: '🐙' }
  ];

  const testimonials = [
    {
      quote: "Reduced our Azure deployment time from 3 weeks to 45 minutes. Game changer!",
      author: "John Smith",
      role: "CTO, TechCorp",
      avatar: "👨‍💼"
    },
    {
      quote: "Best-in-class security posture out of the box. Our auditors were impressed.",
      author: "Sarah Johnson",
      role: "CISO, FinanceHub",
      avatar: "👩‍💼"
    },
    {
      quote: "Saved $850K annually on Azure costs with their optimization recommendations.",
      author: "Mike Chen",
      role: "VP Engineering, DataFlow",
      avatar: "👨‍💻"
    }
  ];

  const getColorClasses = (color) => {
    const colors = {
      blue: 'bg-blue-100 text-blue-600',
      yellow: 'bg-yellow-100 text-yellow-600',
      green: 'bg-green-100 text-green-600',
      purple: 'bg-purple-100 text-purple-600'
    };
    return colors[color] || colors.blue;
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50 to-indigo-50">
      <Navigation currentPage="home" showBack={false} />

      {/* Animated Background Elements */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute -top-40 -right-40 w-80 h-80 bg-blue-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob"></div>
        <div className="absolute -bottom-40 -left-40 w-80 h-80 bg-purple-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob animation-delay-2000"></div>
        <div className="absolute top-40 left-40 w-80 h-80 bg-indigo-200 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-blob animation-delay-4000"></div>
      </div>

      {/* Main Content */}
      <div className="relative max-w-7xl mx-auto px-4 py-20">
        {/* Hero Section */}
        <div className="text-center mb-16">
          <div className="inline-flex items-center bg-blue-100 text-blue-700 px-4 py-2 rounded-full text-sm font-semibold mb-6 hover:bg-blue-200 transition-colors">
            <Award className="w-4 h-4 mr-2" />
            Microsoft Azure Gold Partner
          </div>
          <h1 className="text-6xl md:text-7xl font-bold text-gray-900 mb-6 leading-tight">
            Enterprise Azure Infrastructure
            <br />
            <span className="bg-gradient-to-r from-blue-600 via-indigo-600 to-purple-600 bg-clip-text text-transparent">
              Deployed in Minutes
            </span>
          </h1>
          <p className="text-xl text-gray-600 max-w-3xl mx-auto mb-12 leading-relaxed">
            Production-ready Azure Cloud Adoption Framework Landing Zone with enterprise security,
            compliance, and cost optimization built-in. <span className="font-semibold text-gray-900">No Azure expertise required.</span>
          </p>
          <div className="flex items-center justify-center space-x-4">
            <button
              onClick={() => window.location.href = '/packages'}
              className="group bg-gradient-to-r from-blue-600 to-indigo-600 text-white px-8 py-4 rounded-xl font-bold text-lg hover:shadow-2xl hover:scale-105 transition-all flex items-center"
            >
              Start Free Trial
              <ArrowRight className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform" />
            </button>
            <button className="bg-white text-gray-700 px-8 py-4 rounded-xl font-bold text-lg border-2 border-gray-200 hover:border-blue-500 hover:shadow-xl transition-all">
              Watch Demo
            </button>
          </div>
        </div>

        {/* Live Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-20">
          <div className="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-lg border border-gray-200 hover:shadow-2xl hover:scale-105 transition-all">
            <div className="flex items-center justify-between mb-2">
              <Users className="w-8 h-8 text-blue-600" />
              <span className="text-green-500 text-sm font-semibold">↑ 24%</span>
            </div>
            <div className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
              {stats.customers}+
            </div>
            <div className="text-gray-600 text-sm">Enterprise Customers</div>
          </div>
          <div className="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-lg border border-gray-200 hover:shadow-2xl hover:scale-105 transition-all">
            <div className="flex items-center justify-between mb-2">
              <Server className="w-8 h-8 text-green-600" />
              <span className="text-green-500 text-sm font-semibold">↑ 156%</span>
            </div>
            <div className="text-3xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent">
              {stats.deployments}
            </div>
            <div className="text-gray-600 text-sm">Successful Deployments</div>
          </div>
          <div className="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-lg border border-gray-200 hover:shadow-2xl hover:scale-105 transition-all">
            <div className="flex items-center justify-between mb-2">
              <CheckCircle2 className="w-8 h-8 text-purple-600" />
              <span className="text-green-500 text-sm font-semibold">↑ 0.2%</span>
            </div>
            <div className="text-3xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent">
              {stats.uptime.toFixed(1)}%
            </div>
            <div className="text-gray-600 text-sm">Platform Uptime</div>
          </div>
          <div className="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-lg border border-gray-200 hover:shadow-2xl hover:scale-105 transition-all">
            <div className="flex items-center justify-between mb-2">
              <TrendingUp className="w-8 h-8 text-yellow-600" />
              <span className="text-green-500 text-sm font-semibold">↑ 42%</span>
            </div>
            <div className="text-3xl font-bold bg-gradient-to-r from-yellow-600 to-orange-600 bg-clip-text text-transparent">
              ${(stats.savings / 1000).toFixed(0)}M+
            </div>
            <div className="text-gray-600 text-sm">Total Cost Savings</div>
          </div>
        </div>

        {/* Features Grid */}
        <div id="features" className="mb-20">
          <h2 className="text-4xl font-bold text-center text-gray-900 mb-4">
            Why Choose Our Platform
          </h2>
          <p className="text-center text-gray-600 mb-12 text-lg">
            Enterprise-grade Azure infrastructure with zero DevOps overhead
          </p>
          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-8">
            {features.map((feature, index) => {
              const Icon = feature.icon;
              const colorClass = getColorClasses(feature.color);
              return (
                <div
                  key={index}
                  className="group bg-white/80 backdrop-blur-sm rounded-2xl p-8 shadow-lg border-2 border-gray-100 hover:border-blue-300 hover:shadow-2xl transition-all hover:-translate-y-2"
                >
                  <div className={`w-16 h-16 ${colorClass.split(' ')[0]} rounded-2xl flex items-center justify-center mb-6 group-hover:scale-110 transition-transform`}>
                    <Icon className={`w-8 h-8 ${colorClass.split(' ')[1]}`} />
                  </div>
                  <h3 className="text-xl font-bold text-gray-900 mb-3">{feature.title}</h3>
                  <p className="text-gray-600 leading-relaxed">{feature.description}</p>
                </div>
              );
            })}
          </div>
        </div>

        {/* Trust Badges */}
        <div id="security" className="bg-white/80 backdrop-blur-sm rounded-3xl p-12 shadow-xl border-2 border-gray-200 mb-20">
          <h3 className="text-3xl font-bold text-center text-gray-900 mb-8">
            Enterprise Security & Compliance
          </h3>
          <div className="grid grid-cols-2 md:grid-cols-5 gap-8">
            {['SOC 2 Type II', 'ISO 27001', 'HIPAA', 'GDPR', 'PCI-DSS'].map((cert, index) => (
              <div key={index} className="text-center group hover:scale-105 transition-transform">
                <div className="w-24 h-24 bg-gradient-to-br from-blue-100 to-indigo-100 rounded-2xl flex items-center justify-center mx-auto mb-4 group-hover:shadow-lg transition-shadow">
                  <Shield className="w-12 h-12 text-blue-600 group-hover:scale-110 transition-transform" />
                </div>
                <div className="font-bold text-gray-900">{cert}</div>
                <div className="text-sm text-green-600">✓ Certified</div>
              </div>
            ))}
          </div>
        </div>

        {/* Testimonials */}
        <div className="mb-20">
          <h2 className="text-4xl font-bold text-center text-gray-900 mb-12">
            Trusted by Industry Leaders
          </h2>
          <div className="grid md:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <div key={index} className="bg-white/80 backdrop-blur-sm rounded-2xl p-8 shadow-lg border-2 border-gray-100 hover:border-blue-300 hover:shadow-2xl hover:-translate-y-2 transition-all">
                <div className="text-5xl mb-4">{testimonial.avatar}</div>
                <p className="text-gray-700 mb-6 italic leading-relaxed">"{testimonial.quote}"</p>
                <div>
                  <div className="font-bold text-gray-900">{testimonial.author}</div>
                  <div className="text-sm text-gray-600">{testimonial.role}</div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Partners */}
        <div className="text-center mb-20">
          <p className="text-gray-600 mb-6">Powered by industry-leading technologies</p>
          <div className="flex flex-wrap items-center justify-center gap-8 md:gap-12">
            {partners.map((partner, index) => (
              <div key={index} className="flex items-center space-x-2 hover:scale-110 transition-transform">
                <span className="text-4xl">{partner.logo}</span>
                <span className="text-xl font-bold text-gray-700">{partner.name}</span>
              </div>
            ))}
          </div>
        </div>

        {/* CTA Section */}
        <div id="pricing" className="bg-gradient-to-r from-blue-600 via-indigo-600 to-purple-600 rounded-3xl p-16 text-center text-white shadow-2xl">
          <h2 className="text-4xl md:text-5xl font-bold mb-6">
            Ready to Transform Your Azure Infrastructure?
          </h2>
          <p className="text-xl mb-8 opacity-90">
            Join 250+ enterprises who deployed production-ready infrastructure in minutes
          </p>
          <button
            onClick={() => window.location.href = '/packages'}
            className="bg-white text-blue-600 px-10 py-5 rounded-xl font-bold text-lg hover:shadow-2xl hover:scale-105 transition-all inline-flex items-center space-x-2"
          >
            <span>Start Your Free Trial</span>
            <ArrowRight className="w-5 h-5" />
          </button>
          <p className="text-sm mt-4 opacity-75">No credit card required • 14-day free trial • Cancel anytime</p>
        </div>
      </div>

      {/* Footer */}
      <footer className="relative bg-gray-900 text-white py-12 mt-20">
        <div className="max-w-7xl mx-auto px-4 text-center">
          <div className="flex items-center justify-center space-x-3 mb-4">
            <Cloud className="w-8 h-8" />
            <span className="text-2xl font-bold">Azure CAF-LZ</span>
          </div>
          <p className="text-gray-400 mb-4">Enterprise Azure Infrastructure Platform</p>
          <div className="flex items-center justify-center space-x-6 text-sm text-gray-400">
            <a href="#" className="hover:text-white transition-colors">Privacy Policy</a>
            <a href="#" className="hover:text-white transition-colors">Terms of Service</a>
            <a href="#" className="hover:text-white transition-colors">Contact Us</a>
          </div>
          <p className="text-gray-500 text-sm mt-6">© 2025 Azure CAF-LZ. All rights reserved.</p>
        </div>
      </footer>

      <style jsx>{`
        @keyframes blob {
          0%, 100% { transform: translate(0, 0) scale(1); }
          33% { transform: translate(30px, -50px) scale(1.1); }
          66% { transform: translate(-20px, 20px) scale(0.9); }
        }
        .animate-blob {
          animation: blob 7s infinite;
        }
        .animation-delay-2000 {
          animation-delay: 2s;
        }
        .animation-delay-4000 {
          animation-delay: 4s;
        }
      `}</style>
    </div>
  );
};

export default Home;
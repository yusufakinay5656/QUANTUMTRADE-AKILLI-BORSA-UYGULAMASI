const API_BASE_URL = 'http://localhost:3000/api';

// Token'ı localStorage'dan alma
const getToken = () => {
    return localStorage.getItem('token');
};

// API istekleri için temel ayarlar
const apiRequest = async (endpoint, options = {}) => {
    const token = getToken();
    const headers = {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
        ...options.headers
    };

    try {
        const response = await fetch(`${API_BASE_URL}${endpoint}`, {
            ...options,
            headers,
            body: options.body ? JSON.stringify(options.body) : undefined
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || 'Bir hata oluştu');
        }

        return data;
    } catch (error) {
        console.error('API Hatası:', error);
        throw error;
    }
};

// Kullanıcı işlemleri
export const authAPI = {
    // Kayıt olma
    register: async (userData) => {
        return apiRequest('/auth/register', {
            method: 'POST',
            body: userData
        });
    },

    // Giriş yapma
    login: async (credentials) => {
        return apiRequest('/auth/login', {
            method: 'POST',
            body: credentials
        });
    }
};

// Borsa işlemleri
export const marketAPI = {
    // Hisse senedi satın alma
    buyStock: async (stockData) => {
        return apiRequest('/market/buy', {
            method: 'POST',
            body: stockData
        });
    },

    // Hisse senedi satma
    sellStock: async (stockData) => {
        return apiRequest('/market/sell', {
            method: 'POST',
            body: stockData
        });
    },

    // Portföy bilgilerini getirme
    getPortfolio: async () => {
        return apiRequest('/user/portfolio', {
            method: 'GET'
        });
    },

    // Hisse senedi fiyatını getirme
    getStockPrice: async (symbol) => {
        return apiRequest(`/market/price/${symbol}`, {
            method: 'GET'
        });
    }
};

// Kullanıcı işlemleri
export const userAPI = {
    // Kullanıcı bilgilerini güncelleme
    updateProfile: async (userData) => {
        return apiRequest('/user/profile', {
            method: 'PUT',
            body: userData
        });
    },

    // Şifre değiştirme
    changePassword: async (passwordData) => {
        return apiRequest('/user/password', {
            method: 'PUT',
            body: passwordData
        });
    }
}; 
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const authRoutes = require('./routes/auth');
const marketRoutes = require('./routes/market');

// Çevre değişkenlerini yükle
dotenv.config();

const app = express();

// CORS ayarları
app.use(cors());

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// MongoDB bağlantısı
mongoose.connect('mongodb://localhost:27017/quantumtrade')
  .then(() => console.log('MongoDB bağlantısı başarılı'))
  .catch(err => console.error('MongoDB bağlantı hatası:', err));

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/market', marketRoutes);

// Test endpoint
app.get('/api/test', (req, res) => {
  res.json({ message: 'API çalışıyor!' });
});

// Statik dosyalar için
app.use(express.static(path.join(__dirname, '../web/piyasa')));

// Face-API.js modelleri için
app.use('/models', express.static(path.join(__dirname, '../web/piyasa/models')));

// 404 handler - API istekleri için
app.use('/api/*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'API endpoint bulunamadı'
  });
});

// 404 handler - Diğer istekler için
app.use((req, res) => {
  res.status(404).sendFile(path.join(__dirname, '../web/piyasa/404.html'));
});

// Hata yakalama middleware
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ message: 'Sunucu hatası' });
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Sunucu ${PORT} portunda çalışıyor`);
  console.log(`API endpoint: http://localhost:${PORT}/api`);
}); 
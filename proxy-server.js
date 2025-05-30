const express = require('express');
const cors = require('cors');
const axios = require('axios');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// CORS ve JSON middleware
app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'web')));

// Binance API endpoint
const BINANCE_API = 'https://api.binance.com/api/v3';

// Hata yakalama middleware'i
app.use((err, req, res, next) => {
    console.error('Sunucu hatası:', err);
    res.status(500).json({ error: 'Sunucu hatası' });
});

// 24 saatlik ticker verisi
app.get('/api/ticker/:symbol', async (req, res) => {
    try {
        console.log(`${req.params.symbol} için ticker verisi isteniyor...`);
        const response = await axios.get(`${BINANCE_API}/ticker/24hr`, {
            params: { symbol: req.params.symbol }
        });
        console.log(`${req.params.symbol} ticker verisi başarıyla alındı`);
        res.json(response.data);
    } catch (error) {
        console.error('Ticker verisi alınamadı:', error.message);
        res.status(500).json({ error: 'Veri alınamadı', details: error.message });
    }
});

// Kline (mum) verisi
app.get('/api/klines/:symbol', async (req, res) => {
    try {
        console.log(`${req.params.symbol} için kline verisi isteniyor...`);
        const response = await axios.get(`${BINANCE_API}/klines`, {
            params: {
                symbol: req.params.symbol,
                interval: req.query.interval || '1h',
                limit: req.query.limit || 100
            }
        });
        console.log(`${req.params.symbol} kline verisi başarıyla alındı`);
        res.json(response.data);
    } catch (error) {
        console.error('Kline verisi alınamadı:', error.message);
        res.status(500).json({ error: 'Veri alınamadı', details: error.message });
    }
});

// Teknik analiz verisi
app.get('/api/analysis/:symbol', async (req, res) => {
    try {
        console.log(`${req.params.symbol} için teknik analiz verisi isteniyor...`);
        const [ticker, klines] = await Promise.all([
            axios.get(`${BINANCE_API}/ticker/24hr`, { params: { symbol: req.params.symbol } }),
            axios.get(`${BINANCE_API}/klines`, {
                params: {
                    symbol: req.params.symbol,
                    interval: '1h',
                    limit: 100
                }
            })
        ]);

        const analysis = {
            symbol: req.params.symbol,
            timestamp: new Date().toISOString(),
            price: parseFloat(ticker.data.lastPrice),
            priceChange: parseFloat(ticker.data.priceChangePercent),
            volume: parseFloat(ticker.data.volume),
            highPrice: parseFloat(ticker.data.highPrice),
            lowPrice: parseFloat(ticker.data.lowPrice),
            klines: klines.data.map(k => ({
                time: k[0],
                open: parseFloat(k[1]),
                high: parseFloat(k[2]),
                low: parseFloat(k[3]),
                close: parseFloat(k[4]),
                volume: parseFloat(k[5])
            }))
        };

        console.log(`${req.params.symbol} teknik analiz verisi başarıyla alındı`);
        res.json(analysis);
    } catch (error) {
        console.error('Teknik analiz verisi alınamadı:', error.message);
        res.status(500).json({ error: 'Veri alınamadı', details: error.message });
    }
});

// Sunucuyu başlat
app.listen(PORT, () => {
    console.log(`Proxy sunucu ${PORT} portunda çalışıyor`);
    console.log(`http://localhost:${PORT} adresinden erişilebilir`);
}); 
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const path = require('path');
const WebSocket = require('ws');
const http = require('http');
const axios = require('axios');
const { RSI, MACD, BollingerBands } = require('technicalindicators');
const marketRoutes = require('./routes/market');
const authRoutes = require('./routes/auth');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Middleware
app.use(cors({
  origin: '*', // Geliştirme ortamı için. Prodüksiyonda spesifik origin belirtilmeli
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// Hata yakalama middleware'i
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Sunucu hatası: ' + err.message
  });
});

// MongoDB bağlantısı
mongoose.connect('mongodb://localhost:27017/quantumtrade', {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => {
  console.log('MongoDB bağlantısı başarılı');
}).catch((err) => {
  console.error('MongoDB bağlantı hatası:', err);
});

// Statik dosyaları sun
app.use(express.static(path.join(__dirname, '../')));
app.use('/models', express.static(path.join(__dirname, '../models')));

// Market route'larını ekle
app.use('/api', marketRoutes);

// API Routes
app.use('/api/auth', authRoutes);

// WebSocket bağlantıları
wss.on('connection', (ws) => {
  console.log('Yeni WebSocket bağlantısı');

  // Canlı veri akışı
  const dataInterval = setInterval(async () => {
    try {
      // Binance API'den canlı veri al
      const response = await axios.get('https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT');
      const price = response.data.price;

      ws.send(JSON.stringify({
        type: 'price',
        data: price
      }));
    } catch (error) {
      console.error('Veri alma hatası:', error);
    }
  }, 1000);

  ws.on('close', () => {
    clearInterval(dataInterval);
    console.log('WebSocket bağlantısı kapandı');
  });
});

// Binance API endpoint'leri
const BINANCE_API = 'https://api.binance.com/api/v3';

// Teknik analiz fonksiyonları
function calculateRSI(prices, period = 14) {
    const rsi = new RSI({ values: prices, period });
    return rsi.getResult();
}

function calculateMACD(prices) {
    const macd = new MACD({
        values: prices,
        fastPeriod: 12,
        slowPeriod: 26,
        signalPeriod: 9
    });
    return macd.getResult();
}

function calculateBollingerBands(prices, period = 20, stdDev = 2) {
    const bb = new BollingerBands({
        values: prices,
        period,
        stdDev
    });
    return bb.getResult();
}

// Piyasa verilerini çek
async function getMarketData(symbol = 'BTCUSDT', interval = '1m', limit = 100) {
    try {
        const response = await axios.get(`${BINANCE_API}/klines`, {
            params: {
                symbol,
                interval,
                limit
            }
        });

        const data = response.data.map(candle => ({
            time: candle[0],
            open: parseFloat(candle[1]),
            high: parseFloat(candle[2]),
            low: parseFloat(candle[3]),
            close: parseFloat(candle[4]),
            volume: parseFloat(candle[5])
        }));

        return data;
    } catch (error) {
        console.error('Veri çekme hatası:', error);
        return null;
    }
}

// Piyasa analizi yap
function analyzeMarket(data) {
    if (!data || data.length < 30) {
        return {
            analysis: "Yeterli veri yok",
            trend: "neutral",
            sentiment: "neutral",
            riskLevel: "Orta"
        };
    }

    const closes = data.map(d => d.close);
    const volumes = data.map(d => d.volume);

    // Son fiyat ve değişim
    const lastPrice = closes[closes.length - 1];
    const priceChange = ((lastPrice - closes[closes.length - 2]) / closes[closes.length - 2]) * 100;

    // RSI hesapla
    const rsiValues = calculateRSI(closes);
    const rsi = rsiValues[rsiValues.length - 1];
    let rsiTrend = "neutral";
    if (rsi > 70) rsiTrend = "overbought";
    else if (rsi < 30) rsiTrend = "oversold";

    // MACD hesapla
    const macdValues = calculateMACD(closes);
    const macd = macdValues[macdValues.length - 1];
    let macdTrend = "neutral";
    if (macd.MACD > macd.signal) macdTrend = "bullish";
    else if (macd.MACD < macd.signal) macdTrend = "bearish";

    // Bollinger Bands hesapla
    const bbValues = calculateBollingerBands(closes);
    const bb = bbValues[bbValues.length - 1];
    const bbPosition = (lastPrice - bb.lower) / (bb.upper - bb.lower);

    // Trend belirle
    let trend = "neutral";
    if (priceChange > 0.5 && macdTrend === "bullish" && rsiTrend !== "overbought") {
        trend = "up";
    } else if (priceChange < -0.5 && macdTrend === "bearish" && rsiTrend !== "oversold") {
        trend = "down";
    }

    // Risk seviyesi belirle
    let riskLevel = "Orta";
    if (Math.abs(priceChange) > 2 || rsiTrend in ["overbought", "oversold"]) {
        riskLevel = "Yüksek";
    } else if (Math.abs(priceChange) < 0.5 && rsiTrend === "neutral") {
        riskLevel = "Düşük";
    }

    // Piyasa duyarlılığı
    const sentiment = trend === "up" ? "positive" : "negative";

    // Yapay zeka yorumu oluştur
    const analysis = `
    Güncel fiyat: ${lastPrice.toFixed(2)} (Değişim: ${priceChange.toFixed(2)}%)
    RSI: ${rsi.toFixed(2)} - ${rsiTrend.toUpperCase()}
    MACD: ${macdTrend.toUpperCase()}
    Bollinger Bands pozisyonu: ${bbPosition.toFixed(2)}
    
    Teknik analiz göstergelerine göre piyasa ${trend.toUpperCase()} trendinde hareket ediyor.
    Risk seviyesi: ${riskLevel}
    `;

    return {
        analysis,
        trend,
        sentiment,
        riskLevel
    };
}

// API endpoint'leri
app.get('/api/ai-analysis', async (req, res) => {
    try {
        const marketData = await getMarketData();
        const analysis = analyzeMarket(marketData);
        res.json(analysis);
    } catch (error) {
        console.error('Analiz hatası:', error);
        res.status(500).json({
            error: error.message,
            analysis: "Analiz yapılırken bir hata oluştu",
            trend: "neutral",
            sentiment: "neutral",
            riskLevel: "Orta"
        });
    }
});

// Ana sayfa
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../index.html'));
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`Sunucu ${PORT} portunda çalışıyor`);
  console.log(`http://localhost:${PORT} adresinden erişebilirsiniz`);
  console.log(`WebSocket sunucusu aktif`);
  console.log(`API endpoint: http://localhost:${PORT}/api`);
}); 
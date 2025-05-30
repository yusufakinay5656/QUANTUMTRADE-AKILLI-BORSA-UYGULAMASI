const express = require('express');
const cors = require('cors');
const axios = require('axios');
const WebSocket = require('ws');
const http = require('http');
const path = require('path');

const app = express();
const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

// Middleware
app.use((req, res, next) => {
  console.log('GELEN İSTEK:', req.method, req.url);
  next();
});

app.use(cors());
app.use(express.json());

// Statik dosyaları serve et
// web klasöründeki tüm dosyaları direkt olarak root'tan serve et
app.use(express.static(path.join(__dirname, 'web')));

// Binance API endpoint'leri
const BINANCE_API = {
    KLINE: 'https://api.binance.com/api/v3/klines',
    TICKER: 'https://api.binance.com/api/v3/ticker/24hr',
    DEPTH: 'https://api.binance.com/api/v3/depth'
};

// Aktif bağlantıları tut
let clients = new Set();

// WebSocket bağlantılarını yönet
wss.on('connection', (ws) => {
    clients.add(ws);
    console.log('Yeni WebSocket bağlantısı kuruldu');
    sendMarketDataToAll();
    ws.on('close', () => {
        clients.delete(ws);
        console.log('WebSocket bağlantısı kapandı');
    });
});

// Binance WebSocket bağlantısı
const binanceWs = new WebSocket('wss://stream.binance.com:9443/ws');

// Tüm semboller için stream oluştur
const streams = ['btcusdt@trade'].join('/');
binanceWs.on('open', () => {
    console.log('Binance WebSocket bağlantısı kuruldu');
    binanceWs.send(JSON.stringify({
        method: 'SUBSCRIBE',
        params: streams,
        id: 1
    }));
});

// WebSocket verilerini işle
binanceWs.on('message', async (data) => {
    try {
        const message = JSON.parse(data);
        if (message.e === 'trade') {
            console.log('Yeni trade verisi geldi, market verileri güncelleniyor');
            await sendMarketDataToAll();
        }
    } catch (error) {
        console.error('WebSocket veri işleme hatası:', error);
    }
});

// TradingView teknik analiz fonksiyonları
async function analyzeChart(symbol, interval = '1m', limit = 100) {
    try {
        // Mum verilerini al
        const response = await axios.get(BINANCE_API.KLINE, {
            params: { symbol, interval, limit }
        });
        const candles = response.data;

        // Eğer veri yoksa hata fırlat
        if (!candles || candles.length === 0) {
             throw new Error('Grafik verisi alınamadı');
        }

        // Fiyat verilerini hazırla
        const prices = candles.map(candle => ({
            time: candle[0],
            open: parseFloat(candle[1]),
            high: parseFloat(candle[2]),
            low: parseFloat(candle[3]),
            close: parseFloat(candle[4]),
            volume: parseFloat(candle[5])
        }));

        // Teknik göstergeleri hesapla
        const indicators = calculateIndicators(prices);
        
        // Trend analizi
        const trend = analyzeTrend(prices, indicators);
        
        // Momentum analizi
        const momentum = analyzeMomentum(prices, indicators);
        
        // Hacim analizi
        const volume = analyzeVolume(prices);
        
        // Alım/satım sinyalleri
        const signals = generateSignals(prices, indicators);

        return {
            symbol,
            timestamp: new Date().toISOString(),
            currentPrice: prices[prices.length - 1].close,
            indicators,
            trend,
            momentum,
            volume,
            signals
        };
    } catch (error) {
        console.error(`Chart analiz hatası (${symbol}):`, error);
        return { symbol, error: error.message };
    }
}

// Teknik göstergeleri hesapla
function calculateIndicators(prices) {
    const closes = prices.map(p => p.close);
    const volumes = prices.map(p => p.volume);
    
    // RSI (14 periyot)
    const rsi = calculateRSI(closes);
    
    // MACD (12, 26, 9)
    const macd = calculateMACD(closes);
    
    // Bollinger Bands (20 periyot, 2 standart sapma)
    const bollinger = calculateBollingerBands(closes);
    
    // Stochastic Oscillator (14, 3, 3)
    const stoch = calculateStochastic(prices);
    
    return {
        rsi,
        macd,
        bollinger,
        stoch
    };
}

// RSI hesaplama
function calculateRSI(prices, period = 14) {
    let gains = 0;
    let losses = 0;
    
    for (let i = 1; i < period + 1; i++) {
        const change = prices[prices.length - i] - prices[prices.length - i - 1];
        if (change >= 0) {
            gains += change;
        } else {
            losses -= change;
        }
    }
    
    const avgGain = gains / period;
    const avgLoss = losses / period;
    const rs = avgGain / avgLoss;
    return 100 - (100 / (1 + rs));
}

// MACD hesaplama
function calculateMACD(prices) {
    const ema12 = calculateEMA(prices, 12);
    const ema26 = calculateEMA(prices, 26);
    const macdLine = ema12 - ema26;
    const signalLine = calculateEMA([...Array(9).fill(0), macdLine], 9);
    const histogram = macdLine - signalLine;
    
    return { macdLine, signalLine, histogram };
}

// EMA hesaplama
function calculateEMA(prices, period) {
    const multiplier = 2 / (period + 1);
    let ema = prices[0];
    
    for (let i = 1; i < prices.length; i++) {
        ema = (prices[i] - ema) * multiplier + ema;
    }
    
    return ema;
}

// Bollinger Bands hesaplama
function calculateBollingerBands(prices, period = 20, stdDev = 2) {
    const sma = prices.slice(-period).reduce((sum, price) => sum + price, 0) / period;
    
    const squaredDifferences = prices.slice(-period).map(price => Math.pow(price - sma, 2));
    const variance = squaredDifferences.reduce((sum, diff) => sum + diff, 0) / period;
    const standardDeviation = Math.sqrt(variance);
    
    return {
        upper: sma + (standardDeviation * stdDev),
        middle: sma,
        lower: sma - (standardDeviation * stdDev)
    };
}

// Stochastic Oscillator hesaplama
function calculateStochastic(prices, period = 14, smoothK = 3, smoothD = 3) {
    const lows = prices.slice(-period).map(p => p.low);
    const highs = prices.slice(-period).map(p => p.high);
    const closes = prices.slice(-period).map(p => p.close);
    
    const lowestLow = Math.min(...lows);
    const highestHigh = Math.max(...highs);
    const currentClose = closes[closes.length - 1];
    
    const k = ((currentClose - lowestLow) / (highestHigh - lowestLow)) * 100;
    const d = calculateSMA([...Array(smoothD).fill(0), k], smoothK);
    
    return { k, d };
}

// SMA hesaplama
function calculateSMA(prices, period) {
    return prices.slice(-period).reduce((sum, price) => sum + price, 0) / period;
}

// Trend analizi
function analyzeTrend(prices, indicators) {
    const currentPrice = prices[prices.length - 1].close;
    const { bollinger, macd } = indicators;
    
    // Trend gücü hesaplama
    const trendStrength = calculateTrendStrength(prices, indicators);
    
    // Trend yönü belirleme
    let direction = 'YATAY';
    if (currentPrice > bollinger.upper && macd.histogram > 0) {
        direction = 'GÜÇLÜ YÜKSELİŞ';
    } else if (currentPrice < bollinger.lower && macd.histogram < 0) {
        direction = 'GÜÇLÜ DÜŞÜŞ';
    } else if (currentPrice > bollinger.middle && macd.histogram > 0) {
        direction = 'YÜKSELİŞ';
    } else if (currentPrice < bollinger.middle && macd.histogram < 0) {
        direction = 'DÜŞÜŞ';
    }
    
    return {
        direction,
        strength: trendStrength
    };
}

// Trend gücü hesaplama
function calculateTrendStrength(prices, indicators) {
    const { rsi, macd, bollinger } = indicators;
    
    // RSI ağırlığı
    const rsiWeight = Math.abs(rsi - 50) / 50;
    
    // MACD ağırlığı
    const macdWeight = Math.abs(macd.histogram) / Math.max(...prices.map(p => p.high));
    
    // Bollinger Bands ağırlığı
    const bbWeight = Math.abs(prices[prices.length - 1].close - bollinger.middle) / 
                    (bollinger.upper - bollinger.lower);
    
    return (rsiWeight * 0.4 + macdWeight * 0.3 + bbWeight * 0.3) * 100;
}

// Momentum analizi
function analyzeMomentum(prices, indicators) {
    const { rsi, stoch, macd } = indicators;
    
    // Momentum gücü
    const strength = calculateMomentumStrength(rsi, stoch, macd);
    
    // Momentum yönü
    let direction = 'NÖTR';
    if (rsi > 70 && stoch.k > 80 && macd.histogram > 0) {
        direction = 'GÜÇLÜ YUKARI';
    } else if (rsi < 30 && stoch.k < 20 && macd.histogram < 0) {
        direction = 'GÜÇLÜ AŞAĞI';
    } else if (rsi > 50 && stoch.k > 50 && macd.histogram > 0) {
        direction = 'YUKARI';
    } else if (rsi < 50 && stoch.k < 50 && macd.histogram < 0) {
        direction = 'AŞAĞI';
    }
    
    return {
        direction,
        strength,
        stoch
    };
}

// Momentum gücü hesaplama
function calculateMomentumStrength(rsi, stoch, macd) {
    const rsiStrength = Math.abs(rsi - 50) / 50;
    const stochStrength = Math.abs(stoch.k - 50) / 50;
    const macdStrength = Math.abs(macd.histogram) / Math.max(Math.abs(macd.macdLine), Math.abs(macd.signalLine));
    
    return (rsiStrength * 0.4 + stochStrength * 0.3 + macdStrength * 0.3) * 100;
}

// Hacim analizi
function analyzeVolume(prices) {
    const volumes = prices.map(p => p.volume);
    const avgVolume = volumes.reduce((sum, vol) => sum + vol, 0) / volumes.length;
    const currentVolume = volumes[volumes.length - 1];
    const volumeChange = ((currentVolume - avgVolume) / avgVolume) * 100;
    
    // Hacim trendi
    let trend = 'NORMAL';
    if (volumeChange > 100) {
        trend = 'AŞIRI YÜKSEK';
    } else if (volumeChange > 50) {
        trend = 'YÜKSEK';
    } else if (volumeChange < -50) {
        trend = 'DÜŞÜK';
    }
    
    return {
        current: currentVolume,
        average: avgVolume,
        change: volumeChange,
        trend
    };
}

// Alım/satım sinyalleri üret
function generateSignals(prices, indicators) {
    const signals = [];
    const { rsi, macd, bollinger, stoch } = indicators;
    const currentPrice = prices[prices.length - 1].close;
    
    // RSI sinyalleri
    if (rsi < 30) {
        signals.push({
            type: 'RSI_OVERSOLD',
            strength: (30 - rsi) / 30 * 100,
            action: 'ALIM'
        });
    } else if (rsi > 70) {
        signals.push({
            type: 'RSI_OVERBOUGHT',
            strength: (rsi - 70) / 30 * 100,
            action: 'SATIM'
        });
    }
    
    // MACD sinyalleri
    if (macd.histogram > 0 && macd.macdLine > macd.signalLine) {
        signals.push({
            type: 'MACD_BULLISH',
            strength: Math.abs(macd.histogram) / Math.max(Math.abs(macd.macdLine), Math.abs(macd.signalLine)) * 100,
            action: 'ALIM'
        });
    } else if (macd.histogram < 0 && macd.macdLine < macd.signalLine) {
        signals.push({
            type: 'MACD_BEARISH',
            strength: Math.abs(macd.histogram) / Math.max(Math.abs(macd.macdLine), Math.abs(macd.signalLine)) * 100,
            action: 'SATIM'
        });
    }
    
    // Bollinger Bands sinyalleri
    if (currentPrice < bollinger.lower) {
        signals.push({
            type: 'BB_OVERSOLD',
            strength: ((bollinger.lower - currentPrice) / bollinger.lower) * 100,
            action: 'ALIM'
        });
    } else if (currentPrice > bollinger.upper) {
        signals.push({
            type: 'BB_OVERBOUGHT',
            strength: ((currentPrice - bollinger.upper) / bollinger.upper) * 100,
            action: 'SATIM'
        });
    }
    
    // Stochastic sinyalleri
    if (stoch.k < 20 && stoch.d < 20) {
        signals.push({
            type: 'STOCH_OVERSOLD',
            strength: (20 - Math.min(stoch.k, stoch.d)) / 20 * 100,
            action: 'ALIM'
        });
    } else if (stoch.k > 80 && stoch.d > 80) {
        signals.push({
            type: 'STOCH_OVERBOUGHT',
            strength: (Math.max(stoch.k, stoch.d) - 80) / 20 * 100,
            action: 'SATIM'
        });
    }
    
    return signals;
}

// Sembol-isim ve ikon eşleştirmesi
const COIN_INFO = {
    BTCUSDT: { name: 'Bitcoin', icon: 'https://cryptologos.cc/logos/bitcoin-btc-logo.png' },
    ETHUSDT: { name: 'Ethereum', icon: 'https://cryptologos.cc/logos/ethereum-eth-logo.png' },
    BNBUSDT: { name: 'Binance Coin', icon: 'https://cryptologos.cc/logos/binance-coin-bnb-logo.png' },
    XRPUSDT: { name: 'XRP', icon: 'https://cryptologos.cc/logos/xrp-xrp-logo.png' },
    ADAUSDT: { name: 'Cardano', icon: 'https://cryptologos.cc/logos/cardano-ada-logo.png' },
    SOLUSDT: { name: 'Solana', icon: 'https://cryptologos.cc/logos/solana-sol-logo.png' },
};

// Tüm coinlerin özetini WebSocket ile gönder
async function sendMarketDataToAll() {
    try {
        const analysisPromises = ['BTCUSDT'].map(symbol => analyzeChart(symbol));
        const analyses = await Promise.all(analysisPromises);
        
        const marketData = analyses.map(analysis => {
            if (analysis.error || !analysis.indicators) {
                 return {
                     symbol: analysis.symbol,
                     name: COIN_INFO[analysis.symbol]?.name || analysis.symbol,
                     price: 'Yükleniyor...',
                     trend: { direction: 'Yükleniyor...', strength: '-' },
                     momentum: { direction: 'Yükleniyor...', strength: '-' },
                     volume: { trend: 'Yükleniyor...', change: '-' },
                     indicators: { rsi: 'Yükleniyor...', macd: { histogram: 'Yükleniyor...' } },
                     aiSummary: analysis.error ? `Analiz Hatası: ${analysis.error}` : 'Analiz yükleniyor...'
                 };
            }

            return {
                symbol: analysis.symbol,
                name: COIN_INFO[analysis.symbol]?.name || analysis.symbol,
                price: analysis.currentPrice ? analysis.currentPrice.toFixed(2) : '-',
                icon: COIN_INFO[analysis.symbol]?.icon || '',
                trend: {
                    direction: analysis.trend?.direction || '-',
                    strength: analysis.trend?.strength ? analysis.trend.strength.toFixed(2) : '-'
                },
                momentum: {
                    direction: analysis.momentum?.direction || '-',
                    strength: analysis.momentum?.strength ? analysis.momentum.strength.toFixed(2) : '-'
                },
                volume: {
                    trend: analysis.volume?.trend || '-',
                    change: analysis.volume?.change ? analysis.volume.change.toFixed(2) : '-'
                },
                indicators: {
                    rsi: analysis.indicators?.rsi ? analysis.indicators.rsi.toFixed(2) : '-',
                    macd: {
                        histogram: analysis.indicators?.macd?.histogram ? analysis.indicators.macd.histogram.toFixed(2) : '-'
                    }
                },
                aiSummary: generateChartInterpretation(analysis)
            };
        });
        clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify({
                    type: 'market_data',
                    data: marketData
                }));
            }
        });
    } catch (error) {
        console.error('Market data gönderme hatası:', error);
        clients.forEach(client => {
            if (client.readyState === WebSocket.OPEN) {
                client.send(JSON.stringify({
                    type: 'error',
                    message: 'Market verisi alınamadı. Lütfen daha sonra tekrar deneyin.'
                }));
            }
        });
    }
}

// AI yorumu için yardımcı fonksiyon
function generateChartInterpretation(analysis) {
    if (analysis.error) return `Analiz sırasında hata oluştu: ${analysis.error}`;
    if (!analysis.trend || !analysis.momentum || !analysis.volume || !analysis.indicators) return 'Analiz verileri eksik.';

    const interpretations = [];
    
    if (analysis.trend.direction.includes('YÜKSELİŞ')) {
        interpretations.push('Piyasada yükseliş eğilimi görülüyor.');
    } else if (analysis.trend.direction.includes('DÜŞÜŞ')) {
        interpretations.push('Piyasada düşüş eğilimi görülüyor.');
    } else {
        interpretations.push('Piyasa yatay seyrediyor.');
    }
    
    if (analysis.momentum.direction.includes('YUKARI')) {
         interpretations.push('Momentum yukarı yönlü artıyor.');
    } else if (analysis.momentum.direction.includes('AŞAĞI')) {
         interpretations.push('Momentum aşağı yönlü.');
    }

    if (analysis.indicators.rsi > 70) {
        interpretations.push('RSI aşırı alım bölgesinde.');
    } else if (analysis.indicators.rsi < 30) {
        interpretations.push('RSI aşırı satım bölgesinde.');
    }
    
    if (analysis.volume.trend.includes('YÜKSEK')) {
        interpretations.push('İşlem hacmi yüksek.');
    } else if (analysis.volume.trend.includes('DÜŞÜK')) {
        interpretations.push('İşlem hacmi düşük.');
    }

    if (interpretations.length === 0) return 'Genel piyasa analizi devam ediyor.';
    return interpretations.join(' ');
}

// API endpoint'leri
app.get('/api/market/ai-analysis', async (req, res) => {
    try {
        const analysisPromises = ['BTCUSDT'].map(symbol => analyzeChart(symbol));
        const analyses = await Promise.all(analysisPromises);
        
        res.json({
            timestamp: new Date().toISOString(),
            analyses
        });
    } catch (error) {
        console.error('API Analiz hatası:', error);
        res.status(500).json({ error: 'Analiz sırasında bir hata oluştu' });
    }
});

// Kripto haberleri endpoint'i
app.get('/api/market/crypto-news', async (req, res) => {
    try {
        // CryptoCompare API'den haberleri al
        const response = await axios.get('https://min-api.cryptocompare.com/data/v2/news/?lang=TR');
        const news = response.data.Data.map(item => ({
            title: item.title,
            content: item.body,
            date: new Date(item.published_on * 1000),
            source: item.source,
            url: item.url,
            image: item.imageurl
        }));
        
        res.json(news);
    } catch (error) {
        console.error('Haber alma hatası:', error);
        res.status(500).json({ error: 'Haberler alınırken bir hata oluştu' });
    }
});

// 404 handler
app.use((req, res) => {
    res.status(404).send('Sayfa bulunamadı');
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`Server ${PORT} portunda çalışıyor`);
    console.log(`http://localhost:${PORT}/piyasa/piyasa.html adresinden erişilebilir`);
}); 
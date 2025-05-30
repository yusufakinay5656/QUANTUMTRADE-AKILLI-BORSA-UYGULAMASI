const express = require('express');
const router = express.Router();
const User = require('../models/User');
const jwt = require('jsonwebtoken');
const axios = require('axios');

// Middleware - Kullanıcı doğrulama
const auth = async (req, res, next) => {
  try {
    const authHeader = req.header('Authorization');
    if (!authHeader) {
      return res.status(401).json({ message: 'Yetkilendirme başarısız' });
    }

    const token = authHeader.replace('Bearer ', '');
    const decoded = jwt.verify(token, 'quantumtrade_secret_key_2024');
    const user = await User.findById(decoded.userId);
    if (!user) {
      return res.status(401).json({ message: 'Kullanıcı bulunamadı' });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('Yetkilendirme hatası:', error);
    res.status(401).json({ message: 'Yetkilendirme başarısız' });
  }
};

// Yatırım satın alma
router.post('/buy', auth, async (req, res) => {
  try {
    console.log('Satın alma isteği alındı:', req.body);
    
    const { amount, type } = req.body;

    if (!amount || !type) {
      return res.status(400).json({ message: 'Lütfen tüm alanları doldurun' });
    }

    // Bakiye kontrolü
    if (req.user.balance < amount) {
      return res.status(400).json({ message: 'Yetersiz bakiye' });
    }

    // Portföy güncelleme
    const existingInvestment = req.user.portfolio.find(inv => inv.type === type);
    
    if (existingInvestment) {
      existingInvestment.amount += parseFloat(amount);
    } else {
      req.user.portfolio.push({
        type,
        amount: parseFloat(amount),
        purchaseDate: new Date()
      });
    }

    // Bakiye güncelleme
    req.user.balance -= parseFloat(amount);
    
    // Kullanıcı bilgilerini kaydet
    await req.user.save();

    console.log('Satın alma başarılı. Güncel kullanıcı bilgileri:', {
      balance: req.user.balance,
      portfolio: req.user.portfolio
    });

    res.json({
      message: 'Satın alma işlemi başarılı',
      user: {
        balance: req.user.balance,
        portfolio: req.user.portfolio
      }
    });
  } catch (error) {
    console.error('Satın alma hatası:', error);
    res.status(500).json({ message: 'İşlem sırasında bir hata oluştu' });
  }
});

// Hisse senedi satma
router.post('/sell', auth, async (req, res) => {
  try {
    const { symbol, quantity, price } = req.body;
    const totalValue = quantity * price;

    // Portföy kontrolü
    const existingStock = req.user.portfolio.find(stock => stock.symbol === symbol);
    if (!existingStock || existingStock.quantity < quantity) {
      return res.status(400).json({ message: 'Yetersiz hisse miktarı' });
    }

    // Portföy güncelleme
    existingStock.quantity -= quantity;
    if (existingStock.quantity === 0) {
      req.user.portfolio = req.user.portfolio.filter(stock => stock.symbol !== symbol);
    }

    // Bakiye güncelleme
    req.user.balance += totalValue;
    await req.user.save();

    res.json({
      message: 'İşlem başarılı',
      portfolio: req.user.portfolio,
      balance: req.user.balance
    });
  } catch (error) {
    res.status(500).json({ message: 'İşlem sırasında bir hata oluştu' });
  }
});

// Portföy bilgilerini getirme
router.get('/portfolio', auth, async (req, res) => {
  try {
    res.json({
      portfolio: req.user.portfolio,
      balance: req.user.balance
    });
  } catch (error) {
    res.status(500).json({ message: 'Veri getirme sırasında bir hata oluştu' });
  }
});

// Borsa endeksleri için canlı veri
router.get('/indices', async (req, res) => {
  try {
    const response = await axios.get('https://api.binance.com/api/v3/ticker/24hr');
    const indices = response.data
      .filter(item => item.symbol.endsWith('USDT'))
      .map(item => ({
        symbol: item.symbol,
        price: parseFloat(item.lastPrice),
        change: parseFloat(item.priceChangePercent)
      }))
      .slice(0, 10);

    res.json(indices);
  } catch (error) {
    console.error('Borsa verisi alınırken hata:', error);
    res.status(500).json({ message: 'Veri alınırken bir hata oluştu' });
  }
});

// Grafik verileri için endpoint
router.get('/chart-data/:symbol', async (req, res) => {
  try {
    const { symbol } = req.params;
    const response = await axios.get(`https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=1h&limit=24`);
    
    const chartData = response.data.map(item => ({
      time: new Date(item[0]).toLocaleTimeString(),
      open: parseFloat(item[1]),
      high: parseFloat(item[2]),
      low: parseFloat(item[3]),
      close: parseFloat(item[4])
    }));

    res.json(chartData);
  } catch (error) {
    console.error('Grafik verisi alınırken hata:', error);
    res.status(500).json({ message: 'Veri alınırken bir hata oluştu' });
  }
});

// Piyasa durumu için endpoint
router.get('/market-status', async (req, res) => {
  try {
    const response = await axios.get('https://api.binance.com/api/v3/ticker/24hr');
    const marketData = response.data
      .filter(item => item.symbol.endsWith('USDT'))
      .reduce((acc, item) => {
        acc.totalVolume += parseFloat(item.volume);
        acc.totalTrades += parseInt(item.count);
        return acc;
      }, { totalVolume: 0, totalTrades: 0 });

    res.json(marketData);
  } catch (error) {
    console.error('Piyasa durumu alınırken hata:', error);
    res.status(500).json({ message: 'Veri alınırken bir hata oluştu' });
  }
});

// Ana sayfa için canlı piyasa verileri
router.get('/live-market-data', async (req, res) => {
  try {
    const response = await axios.get('https://api.binance.com/api/v3/ticker/24hr');
    const marketData = response.data
      .filter(item => item.symbol.endsWith('USDT'))
      .map(item => ({
        symbol: item.symbol,
        price: parseFloat(item.lastPrice),
        change: parseFloat(item.priceChangePercent),
        high: parseFloat(item.highPrice),
        low: parseFloat(item.lowPrice),
        volume: parseFloat(item.volume),
        trades: parseInt(item.count)
      }))
      .sort((a, b) => Math.abs(b.change) - Math.abs(a.change))
      .slice(0, 10);

    res.json(marketData);
  } catch (error) {
    console.error('Canlı piyasa verisi alınırken hata:', error);
    res.status(500).json({ message: 'Veri alınırken bir hata oluştu' });
  }
});

// Popüler coinler için endpoint (Binance + CoinGecko fallback)
router.get('/popular', async (req, res) => {
  const symbols = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT'];
  try {
    // Binance API
    const response = await axios.get('https://api.binance.com/api/v3/ticker/24hr');
    const popular = response.data
      .filter(item => symbols.includes(item.symbol))
      .map(item => ({
        symbol: item.symbol,
        price: parseFloat(item.lastPrice),
        change: parseFloat(item.priceChangePercent)
      }));
    if (popular.length === 3) return res.json(popular);
    throw new Error('Eksik veri');
  } catch (err) {
    try {
      // CoinGecko fallback
      const cg = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,binancecoin&vs_currencies=usd&include_24hr_change=true');
      const map = {
        bitcoin: 'BTCUSDT',
        ethereum: 'ETHUSDT',
        binancecoin: 'BNBUSDT'
      };
      const popular = Object.entries(cg.data).map(([key, val]) => ({
        symbol: map[key],
        price: val.usd,
        change: val.usd_24h_change
      }));
      return res.json(popular);
    } catch (e) {
      return res.status(500).json({ message: 'Veri alınamadı' });
    }
  }
});

// Anlık piyasa verileri için çoklu API endpoint
router.get('/live-ticker', async (req, res) => {
  const symbols = ['BTCUSDT', 'ETHUSDT', 'BNBUSDT'];
  try {
    // Binance API
    const response = await axios.get('https://api.binance.com/api/v3/ticker/24hr');
    const data = response.data.filter(item => symbols.includes(item.symbol)).map(item => ({
      symbol: item.symbol,
      price: parseFloat(item.lastPrice),
      change: parseFloat(item.priceChangePercent)
    }));
    if (data.length === 3) return res.json(data);
    throw new Error('Eksik veri');
  } catch (err) {
    try {
      // CoinGecko fallback
      const cg = await axios.get('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,binancecoin&vs_currencies=usd&include_24hr_change=true');
      const map = {
        bitcoin: 'BTCUSDT',
        ethereum: 'ETHUSDT',
        binancecoin: 'BNBUSDT'
      };
      const data = Object.entries(cg.data).map(([key, val]) => ({
        symbol: map[key],
        price: val.usd,
        change: val.usd_24h_change
      }));
      return res.json(data);
    } catch (e) {
      return res.status(500).json({ message: 'Veri alınamadı' });
    }
  }
});

// Canlı grafik verisi (saniyelik/günlük) endpoint
router.get('/chart-live/:symbol', async (req, res) => {
  const { symbol } = req.params;
  try {
    // Binance'tan 1 dakikalık son 24 saatlik mum verisi
    const response = await axios.get(`https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=1m&limit=1440`);
    const data = response.data.map(item => ({
      time: item[0],
      close: parseFloat(item[4])
    }));
    return res.json(data);
  } catch (err) {
    try {
      // CoinGecko fallback (sadece saatlik)
      const cgSymbol = symbol === 'BTCUSDT' ? 'bitcoin' : symbol === 'ETHUSDT' ? 'ethereum' : symbol === 'BNBUSDT' ? 'binancecoin' : '';
      const cg = await axios.get(`https://api.coingecko.com/api/v3/coins/${cgSymbol}/market_chart?vs_currency=usd&days=1&interval=hourly`);
      const data = cg.data.prices.map(item => ({
        time: item[0],
        close: item[1]
      }));
      return res.json(data);
    } catch (e) {
      return res.status(500).json({ message: 'Veri alınamadı' });
    }
  }
});

// Kripto haberleri endpoint'i
router.get('/crypto-news', async (req, res) => {
    try {
        // CryptoCompare API'sini kullanarak haberleri al
        const response = await axios.get('https://min-api.cryptocompare.com/data/v2/news/?lang=TR');
        
        if (response.data && response.data.Data) {
            const news = response.data.Data.map(item => ({
                title: item.title,
                description: item.body,
                url: item.url,
                urlToImage: item.imageurl || 'https://via.placeholder.com/400x250?text=Crypto+News',
                publishedAt: new Date(item.published_on * 1000).toISOString(),
                source: {
                    name: item.source
                }
            })).slice(0, 6); // İlk 6 haberi al

            return res.json(news);
        }

        // Eğer CryptoCompare API çalışmazsa, örnek haberler döndür
        const fallbackNews = [
            {
                title: "Bitcoin Yeni Rekor Seviyeye Ulaştı",
                description: "Bitcoin, son 24 saatte %5 değer kazanarak yeni bir rekor seviyeye ulaştı.",
                url: "#",
                urlToImage: "https://via.placeholder.com/400x250?text=Bitcoin+News",
                publishedAt: new Date().toISOString(),
                source: { name: "CryptoNews" }
            },
            {
                title: "Ethereum 2.0 Güncellemesi Başarılı",
                description: "Ethereum ağı, büyük güncellemeyi başarıyla tamamladı ve işlem hızı artışı sağlandı.",
                url: "#",
                urlToImage: "https://via.placeholder.com/400x250?text=Ethereum+News",
                publishedAt: new Date().toISOString(),
                source: { name: "CryptoNews" }
            },
            {
                title: "Yeni Kripto Para Projesi Duyuruldu",
                description: "Blockchain teknolojisinde çığır açacak yeni bir kripto para projesi duyuruldu.",
                url: "#",
                urlToImage: "https://via.placeholder.com/400x250?text=Crypto+Project",
                publishedAt: new Date().toISOString(),
                source: { name: "CryptoNews" }
            }
        ];

        return res.json(fallbackNews);
    } catch (error) {
        console.error('Haber API hatası:', error);
        // Hata durumunda örnek haberler döndür
        const fallbackNews = [
            {
                title: "Bitcoin Yeni Rekor Seviyeye Ulaştı",
                description: "Bitcoin, son 24 saatte %5 değer kazanarak yeni bir rekor seviyeye ulaştı.",
                url: "#",
                urlToImage: "https://via.placeholder.com/400x250?text=Bitcoin+News",
                publishedAt: new Date().toISOString(),
                source: { name: "CryptoNews" }
            },
            {
                title: "Ethereum 2.0 Güncellemesi Başarılı",
                description: "Ethereum ağı, büyük güncellemeyi başarıyla tamamladı ve işlem hızı artışı sağlandı.",
                url: "#",
                urlToImage: "https://via.placeholder.com/400x250?text=Ethereum+News",
                publishedAt: new Date().toISOString(),
                source: { name: "CryptoNews" }
            },
            {
                title: "Yeni Kripto Para Projesi Duyuruldu",
                description: "Blockchain teknolojisinde çığır açacak yeni bir kripto para projesi duyuruldu.",
                url: "#",
                urlToImage: "https://via.placeholder.com/400x250?text=Crypto+Project",
                publishedAt: new Date().toISOString(),
                source: { name: "CryptoNews" }
            }
        ];
        return res.json(fallbackNews);
    }
});

// Yapay zeka piyasa analizi endpoint'i
router.get('/ai-analysis', async (req, res) => {
  try {
    const response = await axios.get('https://api.binance.com/api/v3/ticker/24hr');
    const marketData = response.data
      .filter(item => item.symbol.endsWith('USDT'))
      .map(item => ({
        symbol: item.symbol,
        price: parseFloat(item.lastPrice),
        change: parseFloat(item.priceChangePercent),
        volume: parseFloat(item.volume),
        trades: parseInt(item.count),
        high: parseFloat(item.highPrice),
        low: parseFloat(item.lowPrice)
      }));

    // Teknik analiz
    const technicalAnalysis = marketData.map(coin => {
      const trend = coin.change > 0 ? 'YÜKSELIŞ' : 'DÜŞÜŞ';
      const strength = Math.abs(coin.change);
      const volumeStrength = coin.volume > 1000000 ? 'YÜKSEK' : 'DÜŞÜK';
      const volatility = ((coin.high - coin.low) / coin.low) * 100;
      
      return {
        symbol: coin.symbol,
        trend,
        strength,
        volumeStrength,
        volatility,
        recommendation: strength > 5 ? 'GÜÇLÜ' : 'ZAYIF'
      };
    });

    // Hacim analizi
    const volumeAnalysis = marketData
      .sort((a, b) => b.volume - a.volume)
      .slice(0, 5)
      .map(coin => ({
        symbol: coin.symbol,
        volume: coin.volume,
        activity: coin.volume > 1000000 ? 'YÜKSEK AKTİVİTE' : 'NORMAL AKTİVİTE'
      }));

    // Momentum analizi
    const momentumAnalysis = marketData
      .sort((a, b) => Math.abs(b.change) - Math.abs(a.change))
      .slice(0, 5)
      .map(coin => ({
        symbol: coin.symbol,
        momentum: Math.abs(coin.change),
        direction: coin.change > 0 ? 'YUKARI' : 'AŞAĞI',
        strength: Math.abs(coin.change) > 5 ? 'GÜÇLÜ' : 'ZAYIF'
      }));

    // Yatırım tavsiyeleri
    const investmentAdvice = marketData
      .map(coin => {
        const trend = coin.change > 0 ? 'YÜKSELIŞ' : 'DÜŞÜŞ';
        const strength = Math.abs(coin.change);
        const volumeStrength = coin.volume > 1000000;
        const volatility = ((coin.high - coin.low) / coin.low) * 100;
        
        // Yapay zeka analiz mantığı
        let confidence = 0;
        let advice = '';
        let reasoning = [];

        // Trend analizi
        if (trend === 'YÜKSELIŞ' && strength > 3) {
          confidence += 30;
          reasoning.push('Güçlü yükseliş trendi');
        } else if (trend === 'DÜŞÜŞ' && strength > 3) {
          confidence -= 30;
          reasoning.push('Güçlü düşüş trendi');
        }

        // Hacim analizi
        if (volumeStrength) {
          confidence += 20;
          reasoning.push('Yüksek işlem hacmi');
        }

        // Volatilite analizi
        if (volatility > 5) {
          confidence += 10;
          reasoning.push('Yüksek volatilite fırsatı');
        }

        // Sonuç değerlendirmesi
        if (confidence >= 50) {
          advice = 'GÜÇLÜ ALIM';
        } else if (confidence >= 30) {
          advice = 'ALIM';
        } else if (confidence <= -50) {
          advice = 'GÜÇLÜ SATIM';
        } else if (confidence <= -30) {
          advice = 'SATIM';
        } else {
          advice = 'BEKLE';
        }

        return {
          symbol: coin.symbol,
          currentPrice: coin.price,
          advice,
          confidence: Math.abs(confidence),
          reasoning,
          riskLevel: volatility > 10 ? 'YÜKSEK' : volatility > 5 ? 'ORTA' : 'DÜŞÜK',
          timestamp: new Date().toISOString()
        };
      })
      .sort((a, b) => b.confidence - a.confidence)
      .slice(0, 5);

    res.json({
      technicalAnalysis,
      volumeAnalysis,
      momentumAnalysis,
      investmentAdvice,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Yapay zeka analizi hatası:', error);
    res.status(500).json({ message: 'Analiz sırasında bir hata oluştu' });
  }
});

// Yatırım tavsiyeleri endpoint'i
router.get('/investment-advice', async (req, res) => {
  try {
    // Örnek veri - gerçek uygulamada bu veriler API'den veya veritabanından gelecek
    const investmentAdvice = {
      opportunities: [
        {
          symbol: 'DOGE',
          action: 'ALIM',
          confidence: 40,
          risk: 'ORTA',
          description: 'Yüksek işlem hacmi • Güçlü momentum • Yüksek volatilite fırsatı'
        },
        {
          symbol: 'ADA',
          action: 'ALIM',
          confidence: 30,
          risk: 'ORTA',
          description: 'Yüksek işlem hacmi • Yüksek volatilite fırsatı'
        },
        {
          symbol: 'ETH',
          action: 'BEKLE',
          confidence: 20,
          risk: 'ORTA',
          description: 'Güçlü momentum • Yüksek volatilite fırsatı'
        },
        {
          symbol: 'BTC',
          action: 'BEKLE',
          confidence: 10,
          risk: 'DÜŞÜK',
          description: 'Güçlü momentum'
        },
        {
          symbol: 'BNB',
          action: 'BEKLE',
          confidence: 0,
          risk: 'DÜŞÜK',
          description: ''
        }
      ],
      technicalAnalysis: [
        { symbol: 'BTC', value: 'YÜKSELIŞ (%1.39)', isPositive: true },
        { symbol: 'ETH', value: 'YÜKSELIŞ (%0.94)', isPositive: true },
        { symbol: 'BNB', value: 'YÜKSELIŞ (%1.13)', isPositive: true },
        { symbol: 'ADA', value: 'YÜKSELIŞ (%2.59)', isPositive: true },
        { symbol: 'DOGE', value: 'YÜKSELIŞ (%1.55)', isPositive: true }
      ],
      volumeAnalysis: [
        { symbol: 'BTC', value: 'DÜŞÜŞ', isPositive: false },
        { symbol: 'ETH', value: 'DÜŞÜŞ', isPositive: false },
        { symbol: 'BNB', value: 'DÜŞÜŞ', isPositive: false },
        { symbol: 'ADA', value: 'YÜKSELIŞ', isPositive: true },
        { symbol: 'DOGE', value: 'YÜKSELIŞ', isPositive: true }
      ],
      momentumAnalysis: [
        { symbol: 'BTC', value: 'DÜŞÜŞ (%70.00)', isPositive: false },
        { symbol: 'ETH', value: 'DÜŞÜŞ (%100.00)', isPositive: false },
        { symbol: 'BNB', value: 'DÜŞÜŞ (%0.00)', isPositive: false },
        { symbol: 'ADA', value: 'YÜKSELIŞ (%10.00)', isPositive: true },
        { symbol: 'DOGE', value: 'DÜŞÜŞ (%30.00)', isPositive: false }
      ],
      strategy: [
        'Piyasa genelinde yükseliş trendi devam ediyor.',
        'Yüksek hacimli coinlere odaklanın.',
        'Risk yönetimi için portföyünüzü çeşitlendirin.',
        'Kısa vadeli işlemler için volatilite fırsatlarını değerlendirin.',
        'Uzun vadeli yatırımlar için güçlü temellere sahip coinleri tercih edin.'
      ]
    };

    res.json(investmentAdvice);
  } catch (error) {
    console.error('Yatırım tavsiyesi hatası:', error);
    res.status(500).json({ error: 'Yatırım tavsiyesi alınamadı' });
  }
});

module.exports = router; 
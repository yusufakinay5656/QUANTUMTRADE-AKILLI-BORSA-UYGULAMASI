const express = require('express');
const router = express.Router();
const axios = require('axios');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const ChatHistory = require('../models/ChatHistory');

// API anahtarını .env dosyasından al
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

// Rate limiter için değişkenler
const requestLimits = new Map();
const RATE_LIMIT = 5; // 1 dakikada maksimum istek sayısı
const RATE_WINDOW = 60000; // 1 dakika (milisaniye cinsinden)

// Rate limiter middleware
const rateLimiter = (req, res, next) => {
    const userId = req.user._id.toString();
    const now = Date.now();
    
    if (!requestLimits.has(userId)) {
        requestLimits.set(userId, {
            count: 1,
            resetTime: now + RATE_WINDOW
        });
    } else {
        const userLimit = requestLimits.get(userId);
        
        if (now > userLimit.resetTime) {
            // Süre dolmuşsa sıfırla
            requestLimits.set(userId, {
                count: 1,
                resetTime: now + RATE_WINDOW
            });
        } else if (userLimit.count >= RATE_LIMIT) {
            // Limit aşılmışsa hata döndür
            const waitTime = Math.ceil((userLimit.resetTime - now) / 1000);
            return res.status(429).json({
                error: `Çok fazla istek gönderildi. Lütfen ${waitTime} saniye bekleyin.`
            });
        } else {
            // İstek sayısını artır
            userLimit.count++;
        }
    }
    
    next();
};

// Health check endpoint
router.get('/health', (req, res) => {
    res.json({ status: 'ok', message: 'AI servisi çalışıyor' });
});

// Auth middleware
const auth = async (req, res, next) => {
    try {
        const token = req.header('x-auth-token');
        if (!token) {
            return res.status(401).json({ error: 'Yetkilendirme token\'ı bulunamadı' });
        }

        const decoded = jwt.verify(token, 'quantumtrade_secret_key_2024');
        const user = await User.findById(decoded.userId);
        
        if (!user) {
            return res.status(401).json({ error: 'Geçersiz token' });
        }

        req.user = user;
        next();
    } catch (error) {
        res.status(401).json({ error: 'Token doğrulanamadı' });
    }
};

// Get chat history
router.get('/history', auth, async (req, res) => {
    try {
        const history = await ChatHistory.findOne({ userId: req.user._id });
        res.json({ history: history ? history.messages : [] });
    } catch (error) {
        console.error('Chat history error:', error);
        res.status(500).json({ error: 'Sohbet geçmişi alınamadı' });
    }
});

// Chat endpoint
router.post('/chat', auth, rateLimiter, async (req, res) => {
    try {
        const { message } = req.body;
        if (!message || message.trim().length === 0) {
            return res.status(400).json({ error: 'Mesaj boş olamaz' });
        }

        let chatHistory = await ChatHistory.findOne({ userId: req.user._id });
        if (!chatHistory) {
            chatHistory = new ChatHistory({ userId: req.user._id, messages: [] });
        }

        chatHistory.messages.push({
            content: message,
            role: 'user',
            timestamp: new Date()
        });

        // OpenAI API'ye istek gönder
        const response = await axios.post(
            'https://api.openai.com/v1/chat/completions',
            {
                model: 'gpt-3.5-turbo',
                messages: [
                    { 
                        role: 'system', 
                        content: `Sen QuantumTrade'in kripto para ve borsa uzmanı AI asistansın. 
                        Yanıtların her zaman Türkçe olmalı ve teknik terimleri açıklayıcı olmalı. 
                        Kullanıcıya yatırım tavsiyesi verme. 
                        Yanıtların doğal ve samimi olmalı, sanki gerçek bir uzmanla konuşuyormuş gibi hissettirmeli.
                        Kısa ve öz cevaplar ver, gereksiz tekrarlardan kaçın.
                        Eğer bir konuda emin değilsen, bunu dürüstçe belirt.
                        Her zaman yardımcı olmaya çalış ve kullanıcıyı yönlendir.`
                    },
                    ...chatHistory.messages.slice(-5).map(msg => ({
                        role: msg.role,
                        content: msg.content
                    }))
                ],
                max_tokens: 1024,
                temperature: 0.7,
                presence_penalty: 0.6,
                frequency_penalty: 0.3
            },
            {
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${OPENAI_API_KEY}`
                },
                timeout: 30000
            }
        );

        if (!response.data || !response.data.choices || !response.data.choices[0]) {
            throw new Error('AI yanıtı alınamadı');
        }

        const aiResponse = response.data.choices[0].message.content;

        chatHistory.messages.push({
            content: aiResponse,
            role: 'assistant',
            timestamp: new Date()
        });

        await chatHistory.save();

        res.json({ response: aiResponse });
    } catch (error) {
        console.error('AI Chat Hatası:', error);
        let errorMessage = 'Üzgünüm, şu anda yanıt veremiyorum. Lütfen biraz sonra tekrar deneyin.';
        
        if (error.response) {
            if (error.response.status === 401) {
                errorMessage = 'Sistem yapılandırma hatası. Lütfen daha sonra tekrar deneyin.';
            } else if (error.response.status === 429) {
                const retryAfter = error.response.headers['retry-after'] || 60;
                errorMessage = `Şu anda çok yoğunum. Lütfen ${retryAfter} saniye sonra tekrar deneyin.`;
            } else {
                errorMessage = 'Şu anda teknik bir sorun yaşıyorum. Lütfen biraz sonra tekrar deneyin.';
            }
        } else if (error.request) {
            errorMessage = 'İnternet bağlantınızı kontrol eder misiniz? Şu anda size ulaşamıyorum.';
        } else if (error.code === 'ECONNABORTED') {
            errorMessage = 'Yanıt vermem biraz zaman aldı. Lütfen tekrar deneyin.';
        } else if (error.message.includes('AI yanıtı alınamadı')) {
            errorMessage = 'Şu anda düşüncelerimi toplayamıyorum. Lütfen biraz sonra tekrar deneyin.';
        }
        
        res.status(500).json({ error: errorMessage });
    }
});

module.exports = router; 
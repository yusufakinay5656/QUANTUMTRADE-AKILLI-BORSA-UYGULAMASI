const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Kullanıcı bilgilerini doğrula
router.post('/validate', async (req, res) => {
  try {
    const { email, username } = req.body;
    console.log('Validate request body:', req.body);

    const existingUser = await User.findOne({
      $or: [{ email }, { username }]
    });

    if (existingUser) {
      return res.json({
        success: false,
        message: existingUser.email === email ? 
          'Bu e-posta adresi zaten kullanılıyor' : 
          'Bu kullanıcı adı zaten kullanılıyor'
      });
    }

    res.json({
      success: true,
      message: 'Kullanıcı bilgileri kullanılabilir'
    });

  } catch (error) {
    console.error('Doğrulama hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Doğrulama sırasında bir hata oluştu: ' + error.message
    });
  }
});

// Kayıt olma
router.post('/register', async (req, res) => {
  try {
    console.log('Kayıt isteği alındı:', req.body);
    const { name, surname, username, email, password, faceDescriptor } = req.body;

    // Gerekli alanları kontrol et (faceDescriptor hariç)
    if (!name || !surname || !username || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Tüm alanlar zorunludur'
      });
    }

    // E-posta formatını kontrol et
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        message: 'Geçersiz e-posta formatı'
      });
    }

    // Şifre uzunluğunu kontrol et
    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Şifre en az 6 karakter olmalıdır'
      });
    }

    // Kullanıcı adı veya email kontrolü
    const existingUser = await User.findOne({ $or: [{ username }, { email }] });
    if (existingUser) {
      console.log('Kullanıcı zaten mevcut:', existingUser);
      return res.status(400).json({ 
        success: false,
        message: 'Bu kullanıcı adı veya email zaten kullanımda' 
      });
    }

    // Yüz tanıma verilerini düzgün formata dönüştür (eğer varsa)
    let processedFaceDescriptor = null;
    if (faceDescriptor && Array.isArray(faceDescriptor)) {
      processedFaceDescriptor = faceDescriptor.map(val => parseFloat(val));
    }

    // Yeni kullanıcı oluşturma
    console.log('Yeni kullanıcı oluşturuluyor...');
    const user = new User({ 
      name, 
      surname, 
      username, 
      email, 
      password,
      faceDescriptor: processedFaceDescriptor
    });
    
    // Kullanıcıyı kaydet
    const savedUser = await user.save();
    console.log('Kullanıcı başarıyla kaydedildi:', savedUser);

    // JWT token oluştur
    const token = jwt.sign(
      { userId: savedUser._id },
      'quantumtrade_secret_key_2024',
      { expiresIn: '24h' }
    );

    // CORS başlıklarını ekle
    res.header('Access-Control-Allow-Origin', '*');
    res.header('Access-Control-Allow-Methods', 'POST');
    res.header('Access-Control-Allow-Headers', 'Content-Type');

    res.status(201).json({
      success: true,
      message: 'Kayıt başarılı! Giriş yapabilirsiniz.',
      token,
      user: {
        id: savedUser._id,
        name: savedUser.name,
        surname: savedUser.surname,
        username: savedUser.username,
        email: savedUser.email
      }
    });
  } catch (error) {
    console.error('Kayıt hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Kayıt sırasında bir hata oluştu: ' + error.message
    });
  }
});

// Giriş yapma
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // Kullanıcıyı bulma
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ 
        success: false,
        message: 'Geçersiz email veya şifre' 
      });
    }

    // Şifre kontrolü
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(401).json({ 
        success: false,
        message: 'Geçersiz email veya şifre' 
      });
    }

    // JWT token oluşturma
    const token = jwt.sign(
      { userId: user._id },
      'quantumtrade_secret_key_2024',
      { expiresIn: '24h' }
    );

    res.json({
      success: true,
      message: 'Giriş başarılı! Yönlendiriliyorsunuz...',
      token,
      user: {
        id: user._id,
        name: user.name,
        surname: user.surname,
        username: user.username,
        email: user.email,
        balance: user.balance,
        portfolio: user.portfolio
      }
    });
  } catch (error) {
    console.error('Giriş hatası:', error);
    res.status(500).json({ 
      success: false,
      message: 'Giriş sırasında bir hata oluştu' 
    });
  }
});

// Yüz tanıma ile giriş
router.post('/face-login', async (req, res) => {
  try {
    const { faceDescriptor } = req.body;

    if (!faceDescriptor || !Array.isArray(faceDescriptor)) {
      return res.status(400).json({
        success: false,
        message: 'Geçersiz yüz tanıma verisi'
      });
    }

    // Yüz tanıma verilerini düzgün formata dönüştür
    let processedFaceDescriptor = faceDescriptor.map(val => parseFloat(val));

    // Tüm kullanıcıları getir
    const users = await User.find({ faceDescriptor: { $exists: true, $ne: null } });
    
    if (users.length === 0) {
      console.log('Veritabanında kayıtlı yüz tanıma verisi bulunamadı.');
      return res.status(404).json({
        success: false,
        message: 'Sistemde hiç kayıtlı yüz tanıma verisi yok'
      });
    }

    console.log('Yüz tanıma verisi olan kullanıcı sayısı:', users.length);

    // En yakın eşleşmeyi ve mesafesini bul
    let bestMatch = null;
    let bestDistance = Infinity;
    const threshold = 0.6; // Yüz eşleştirme eşiği (bu değeri test ederek ayarlayabilirsiniz)

    for (const user of users) {
      if (!user.faceDescriptor || user.faceDescriptor.length !== 128) {
        console.log('Geçersiz veya eksik yüz tanıma verisi olan kullanıcı geçildi:', user._id);
        continue;
      }

      // İki yüz descriptor'ı arasındaki Öklid mesafesini hesapla
      const distance = Math.sqrt(
        processedFaceDescriptor.reduce((sum, val, i) => {
          const diff = val - user.faceDescriptor[i];
          return sum + diff * diff;
        }, 0)
      );

      console.log(`Kullanıcı ${user._id} (${user.username}) için mesafe:`, distance);

      // Eğer bu kullanıcı şu ana kadarki en iyi eşleşme ise güncelle
      if (distance < bestDistance) {
        bestDistance = distance;
        bestMatch = user;
      }
    }

    // En iyi eşleşme bulundumu ve eşik altında mı?
    // bestMatch kontrolü önemli çünkü hiç kullanıcı olmama ihtimali var (üstte kontrol ediliyor ama ekstra güvenlik)
    // bestDistance < threshold kontrolü ise eşleşmenin yeterince yakın olduğunu garanti eder.
    if (bestMatch && bestDistance < threshold) {
      console.log('Eşleşme bulundu:', bestMatch._id, 'Mesafe:', bestDistance);
      
      // JWT token oluştur
      const token = jwt.sign(
        { userId: bestMatch._id },
        'quantumtrade_secret_key_2024',
        { expiresIn: '24h' }
      );

      // Son giriş zamanını güncelle
      bestMatch.lastLogin = new Date();
      await bestMatch.save();

      // CORS başlıklarını ekle (gerekliyse, frontend'in origin'ine göre ayarlayın)
      res.header('Access-Control-Allow-Origin', '*'); // Geliştirme ortamı için açık, üretimde spesifik yapın
      res.header('Access-Control-Allow-Methods', 'POST');
      res.header('Access-Control-Allow-Headers', 'Content-Type');

      res.json({
        success: true,
        message: 'Yüz tanıma ile giriş başarılı',
        token,
        user: {
          id: bestMatch._id,
          name: bestMatch.name,
          surname: bestMatch.surname,
          username: bestMatch.username,
          email: bestMatch.email
        }
      });
    } else {
      // Eşleşme bulunamadı veya bulunan en iyi eşleşme eşiği aştı
      console.log('Yüz tanıma eşleşmesi bulunamadı veya eşik aşıldı. En iyi mesafe:', bestDistance);
      res.status(401).json({
        success: false,
        message: 'Kayıtlı yüz tanıma verisi bulunamadı' // Frontend bu mesajı "Bu yüz kayıtlı değil! Lütfen önce üye olun." olarak gösterebilir
      });
    }
  } catch (error) {
    console.error('Yüz tanıma giriş hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Yüz tanıma girişi sırasında bir sistem hatası oluştu: ' + error.message // Genel sistem hatası mesajı
    });
  }
});

module.exports = router; 
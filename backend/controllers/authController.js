const User = require('../models/User');
const jwt = require('jsonwebtoken');

// JWT Secret key
const JWT_SECRET = process.env.JWT_SECRET || 'quantumtrade_secret_key_2024';

// Kullanıcı bilgilerini doğrula
exports.validate = async (req, res) => {
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
};

// Kullanıcı kaydı
exports.register = async (req, res) => {
  try {
    const { name, surname, username, email, password, faceDescriptor } = req.body;

    // E-posta ve kullanıcı adı kontrolü
    const existingUser = await User.findOne({ 
      $or: [{ email }, { username }] 
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: existingUser.email === email ? 
          'Bu e-posta adresi zaten kullanılıyor' : 
          'Bu kullanıcı adı zaten kullanılıyor'
      });
    }

    // Yüz tanıma verilerini düzgün formata dönüştür
    let processedFaceDescriptor = faceDescriptor;
    if (Array.isArray(faceDescriptor)) {
      // Eğer Float32Array içindeyse, normal diziye dönüştür
      processedFaceDescriptor = faceDescriptor.map(val => parseFloat(val));
    }

    // Yeni kullanıcı oluştur
    const user = new User({
      name,
      surname,
      username,
      email,
      password,
      faceDescriptor: processedFaceDescriptor
    });

    await user.save();

    res.status(201).json({
      success: true,
      message: 'Kullanıcı başarıyla kaydedildi'
    });

  } catch (error) {
    console.error('Kayıt hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Kayıt sırasında bir hata oluştu: ' + error.message
    });
  }
};

// Normal giriş
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'E-posta veya şifre hatalı'
      });
    }

    // Şifre kontrolü (gerçek uygulamada hash'lenmiş şifreler kullanılmalı)
    if (user.password !== password) {
      return res.status(401).json({
        success: false,
        message: 'E-posta veya şifre hatalı'
      });
    }

    const token = jwt.sign(
      { id: user._id },
      JWT_SECRET,
      { expiresIn: '1d' }
    );

    res.json({
      success: true,
      message: 'Giriş başarılı',
      token,
      user: {
        id: user._id,
        name: user.name,
        surname: user.surname,
        username: user.username,
        email: user.email
      }
    });

  } catch (error) {
    console.error('Giriş hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Giriş sırasında bir hata oluştu: ' + error.message
    });
  }
};

// Yüz tanıma ile giriş
exports.faceLogin = async (req, res) => {
  try {
    const { faceDescriptor } = req.body;

    // Yüz tanıma verilerini düzgün formata dönüştür
    let processedFaceDescriptor = faceDescriptor;
    if (Array.isArray(faceDescriptor)) {
      processedFaceDescriptor = faceDescriptor.map(val => parseFloat(val));
    }

    // Tüm kullanıcıları getir
    const users = await User.find({ faceDescriptor: { $exists: true } });
    
    if (users.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Kayıtlı yüz tanıma verisi bulunamadı'
      });
    }

    // En yakın eşleşmeyi bul
    let bestMatch = null;
    let bestDistance = Infinity;

    for (const user of users) {
      // Basit Öklid mesafesi hesaplama
      const distance = Math.sqrt(
        processedFaceDescriptor.reduce((sum, val, i) => {
          const diff = val - user.faceDescriptor[i];
          return sum + diff * diff;
        }, 0)
      );

      if (distance < bestDistance) {
        bestDistance = distance;
        bestMatch = user;
      }
    }

    // Eşleşme eşiği (0.6'dan küçük olmalı)
    if (bestDistance < 0.6) {
      const token = jwt.sign(
        { id: bestMatch._id },
        JWT_SECRET,
        { expiresIn: '1d' }
      );

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
      res.status(401).json({
        success: false,
        message: 'Yüz tanıma eşleşmesi bulunamadı'
      });
    }

  } catch (error) {
    console.error('Yüz tanıma giriş hatası:', error);
    res.status(500).json({
      success: false,
      message: 'Yüz tanıma girişi sırasında bir hata oluştu: ' + error.message
    });
  }
}; 
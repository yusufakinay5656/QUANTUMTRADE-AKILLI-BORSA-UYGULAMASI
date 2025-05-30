const jwt = require('jsonwebtoken');

module.exports = function(req, res, next) {
  // Token'ı header'dan al
  const token = req.header('x-auth-token');

  // Token yoksa hata döndür
  if (!token) {
    return res.status(401).json({ message: 'Yetkilendirme reddedildi' });
  }

  try {
    // Token'ı doğrula
    const decoded = jwt.verify(token, 'quantumtrade_secret_key_2024');
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ message: 'Token geçersiz' });
  }
}; 
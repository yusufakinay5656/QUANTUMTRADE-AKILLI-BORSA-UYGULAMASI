const express = require('express');
const router = express.Router();
const User = require('../models/User');
const auth = require('../middleware/auth');

// Kullanıcı bilgilerini getir
router.get('/profile', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json(user);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Sunucu hatası' });
  }
});

// Portföy bilgilerini getir
router.get('/portfolio', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('portfolio balance');
    res.json({
      portfolio: user.portfolio,
      balance: user.balance
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Sunucu hatası' });
  }
});

module.exports = router; 
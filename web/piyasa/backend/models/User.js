const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'İsim alanı zorunludur']
  },
  surname: {
    type: String,
    required: [true, 'Soyisim alanı zorunludur']
  },
  username: {
    type: String,
    required: [true, 'Kullanıcı adı zorunludur'],
    unique: true
  },
  email: {
    type: String,
    required: [true, 'E-posta alanı zorunludur'],
    unique: true,
    match: [/^[^\s@]+@[^\s@]+\.[^\s@]+$/, 'Geçerli bir e-posta adresi giriniz']
  },
  password: {
    type: String,
    required: [true, 'Şifre alanı zorunludur'],
    minlength: [6, 'Şifre en az 6 karakter olmalıdır']
  },
  faceDescriptor: {
    type: [Number],
    required: false,
    validate: {
      validator: function(v) {
        return !v || (Array.isArray(v) && v.length === 128);
      },
      message: 'Face descriptor 128 sayıdan oluşmalıdır'
    }
  },
  balance: {
    type: Number,
    default: 10000
  },
  portfolio: [{
    symbol: String,
    quantity: Number,
    averagePrice: Number
  }],
  lastLogin: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Şifre hashleme
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Şifre karşılaştırma
userSchema.methods.comparePassword = async function(candidatePassword) {
  try {
    return await bcrypt.compare(candidatePassword, this.password);
  } catch (error) {
    throw error;
  }
};

// Yüz tanıma karşılaştırma
userSchema.methods.compareFace = function(faceDescriptor) {
  if (!this.faceDescriptor || !faceDescriptor) {
    throw new Error('Face descriptor bulunamadı');
  }

  if (!Array.isArray(faceDescriptor) || faceDescriptor.length !== 128) {
    throw new Error('Geçersiz face descriptor formatı');
  }

  // Öklid mesafesi hesaplama
  const distance = Math.sqrt(
    faceDescriptor.reduce((sum, val, i) => {
      const diff = val - this.faceDescriptor[i];
      return sum + diff * diff;
    }, 0)
  );

  return distance < 0.6; // Eşleşme eşiği
};

module.exports = mongoose.model('User', userSchema); 
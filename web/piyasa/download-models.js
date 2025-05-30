const https = require('https');
const fs = require('fs');
const path = require('path');

const models = [
  {
    name: 'tiny_face_detector_model-weights_manifest.json',
    url: 'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights/tiny_face_detector_model-weights_manifest.json'
  },
  {
    name: 'tiny_face_detector_model-shard1',
    url: 'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights/tiny_face_detector_model-shard1'
  },
  {
    name: 'face_landmark_68_model-weights_manifest.json',
    url: 'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights/face_landmark_68_model-weights_manifest.json'
  },
  {
    name: 'face_landmark_68_model-shard1',
    url: 'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights/face_landmark_68_model-shard1'
  },
  {
    name: 'face_recognition_model-weights_manifest.json',
    url: 'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights/face_recognition_model-weights_manifest.json'
  },
  {
    name: 'face_recognition_model-shard1',
    url: 'https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights/face_recognition_model-shard1'
  }
];

const modelsDir = path.join(__dirname, 'models');

// Models klasörünü oluştur
if (!fs.existsSync(modelsDir)) {
  fs.mkdirSync(modelsDir, { recursive: true });
}

// Her model için indirme işlemi
models.forEach(model => {
  const filePath = path.join(modelsDir, model.name);
  const file = fs.createWriteStream(filePath);

  https.get(model.url, response => {
    response.pipe(file);

    file.on('finish', () => {
      file.close();
      console.log(`Downloaded: ${model.name}`);
    });
  }).on('error', err => {
    fs.unlink(filePath, () => {}); // Hata durumunda dosyayı sil
    console.error(`Error downloading ${model.name}:`, err.message);
  });
}); 
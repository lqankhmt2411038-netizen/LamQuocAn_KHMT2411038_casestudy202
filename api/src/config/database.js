const mongoose = require('mongoose');

module.exports = async function connectDB() {
  const uri = process.env.MONGODB_URI;
  if (!uri) throw new Error('Thiếu MONGODB_URI trong file .env');
  mongoose.set('strictQuery', true);
  await mongoose.connect(uri);
  console.log('✔ Đã kết nối MongoDB:', mongoose.connection.name);
};

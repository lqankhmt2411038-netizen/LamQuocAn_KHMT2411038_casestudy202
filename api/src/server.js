require('dotenv').config();
const app = require('./app');
const connectDB = require('./config/database');
const { startReminderJob } = require('./services/reminderService');

const PORT = process.env.PORT || 3000;

(async () => {
  try {
    if (!process.env.JWT_SECRET) throw new Error('Thiếu JWT_SECRET trong file .env');
    await connectDB();
    // 0.0.0.0 để máy ảo Android (10.0.2.2) và điện thoại thật cùng mạng truy cập được
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`✔ API chạy tại http://localhost:${PORT}/api`);
    });
    startReminderJob();
  } catch (err) {
    console.error('✖ Không khởi động được server:', err.message);
    process.exit(1);
  }
})();

const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    fullName: { type: String, required: [true, 'Họ tên là bắt buộc'], trim: true, maxlength: 100 },
    email: { type: String, required: true, unique: true, lowercase: true, trim: true },
    // select:false -> không bao giờ trả mật khẩu băm ra ngoài trừ khi yêu cầu rõ ràng
    passwordHash: { type: String, required: true, select: false },
    avatarUrl: { type: String, default: '', trim: true, maxlength: 500 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('User', userSchema);

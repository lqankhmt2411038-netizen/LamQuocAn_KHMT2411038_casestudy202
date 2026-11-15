const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { serializeUser } = require('../utils/serializers');

const signToken = (user) =>
  jwt.sign({ sub: String(user._id) }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });

// POST /auth/register
exports.register = asyncHandler(async (req, res) => {
  const { fullName, email, password } = req.body;

  const existed = await User.findOne({ email });
  if (existed) throw new ApiError(409, 'Email này đã được đăng ký');

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await User.create({ fullName, email, passwordHash });

  res.status(201).json({
    success: true,
    message: 'Đăng ký tài khoản thành công',
    data: { token: signToken(user), user: serializeUser(user) },
  });
});

// POST /auth/login
exports.login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  const user = await User.findOne({ email }).select('+passwordHash');
  // Cùng một thông báo cho cả "sai email" và "sai mật khẩu" để không lộ email nào đã đăng ký
  const ok = user && (await bcrypt.compare(password, user.passwordHash));
  if (!ok) throw new ApiError(401, 'Email hoặc mật khẩu không đúng');

  res.json({
    success: true,
    message: 'Đăng nhập thành công',
    data: { token: signToken(user), user: serializeUser(user) },
  });
});

// GET /auth/me
exports.me = asyncHandler(async (req, res) => {
  res.json({ success: true, data: serializeUser(req.user) });
});

// PUT /auth/me
exports.updateMe = asyncHandler(async (req, res) => {
  const { fullName, avatarUrl } = req.body;
  if (fullName !== undefined) req.user.fullName = fullName;
  if (avatarUrl !== undefined) req.user.avatarUrl = avatarUrl;
  await req.user.save();
  res.json({ success: true, message: 'Cập nhật thông tin thành công', data: serializeUser(req.user) });
});

// PUT /auth/change-password
exports.changePassword = asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  const user = await User.findById(req.user._id).select('+passwordHash');
  const ok = await bcrypt.compare(currentPassword, user.passwordHash);
  if (!ok) throw new ApiError(400, 'Mật khẩu hiện tại không đúng');
  if (currentPassword === newPassword) throw new ApiError(400, 'Mật khẩu mới phải khác mật khẩu hiện tại');

  user.passwordHash = await bcrypt.hash(newPassword, 10);
  await user.save();
  res.json({ success: true, message: 'Đổi mật khẩu thành công' });
});

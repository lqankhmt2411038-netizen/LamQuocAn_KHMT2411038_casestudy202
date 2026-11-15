const User = require('../models/User');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { escapeRegex } = require('../utils/helpers');
const { userRef } = require('../utils/serializers');
const { USER_FIELDS } = require('../utils/constants');

// GET /users/search?q=   (tối thiểu 2 ký tự để tránh liệt kê toàn bộ người dùng)
exports.search = asyncHandler(async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (q.length < 2) return res.json({ success: true, data: [] });

  const rx = new RegExp(escapeRegex(q), 'i');
  const users = await User.find({ $or: [{ fullName: rx }, { email: rx }] })
    .select(USER_FIELDS)
    .sort({ fullName: 1 })
    .limit(20);

  res.json({ success: true, data: users.map(userRef) });
});

// GET /users/:id  (thông tin công khai)
exports.getById = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id).select(USER_FIELDS);
  if (!user) throw new ApiError(404, 'Không tìm thấy người dùng');
  res.json({ success: true, data: userRef(user) });
});

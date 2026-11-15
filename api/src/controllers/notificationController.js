const Notification = require('../models/Notification');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { serializeNotification } = require('../utils/serializers');

// GET /notifications?unread=true
exports.list = asyncHandler(async (req, res) => {
  const filter = { userId: req.user._id };
  if (req.query.unread === 'true') filter.isRead = false;
  const items = await Notification.find(filter).sort({ createdAt: -1 }).limit(100);
  res.json({ success: true, data: items.map(serializeNotification) });
});

// GET /notifications/unread-count
exports.unreadCount = asyncHandler(async (req, res) => {
  const count = await Notification.countDocuments({ userId: req.user._id, isRead: false });
  res.json({ success: true, data: { count } });
});

// PATCH /notifications/:id/read
exports.markRead = asyncHandler(async (req, res) => {
  const n = await Notification.findOneAndUpdate(
    { _id: req.params.id, userId: req.user._id }, // chỉ được đọc thông báo của chính mình
    { $set: { isRead: true } },
    { new: true }
  );
  if (!n) throw new ApiError(404, 'Không tìm thấy thông báo');
  res.json({ success: true, data: serializeNotification(n) });
});

// PATCH /notifications/read-all
exports.markAllRead = asyncHandler(async (req, res) => {
  await Notification.updateMany({ userId: req.user._id, isRead: false }, { $set: { isRead: true } });
  res.json({ success: true, message: 'Đã đánh dấu tất cả là đã đọc' });
});

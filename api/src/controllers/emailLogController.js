const EmailLog = require('../models/EmailLog');
const Task = require('../models/Task');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { retryEmail, MAX_ATTEMPTS } = require('../services/emailService');
const { serializeEmailLog } = require('../utils/serializers');

// GET /tasks/:id/email-logs   (chỉ người tạo công việc)
exports.listByTask = asyncHandler(async (req, res) => {
  const logs = await EmailLog.find({ taskId: req.task._id }).sort({ createdAt: -1 }).limit(100);
  res.json({ success: true, data: logs.map(serializeEmailLog) });
});

// POST /email-logs/:id/retry   (chỉ người tạo công việc, chỉ email 'failed', tối đa N lần)
exports.retry = asyncHandler(async (req, res) => {
  const log = await EmailLog.findById(req.params.id);
  if (!log || !log.taskId) throw new ApiError(404, 'Không tìm thấy lịch sử email');

  const task = await Task.findById(log.taskId).select('createdBy');
  if (!task || String(task.createdBy) !== String(req.user._id)) {
    throw new ApiError(403, 'Bạn không có quyền gửi lại email này');
  }
  if (log.status !== 'failed') throw new ApiError(400, 'Chỉ có thể gửi lại email đã thất bại');
  if (log.attempts >= MAX_ATTEMPTS()) {
    throw new ApiError(400, `Đã thử gửi tối đa ${MAX_ATTEMPTS()} lần`);
  }

  const updated = await retryEmail(log._id);
  if (!updated) throw new ApiError(409, 'Email đang được xử lý, vui lòng thử lại sau');
  res.json({ success: true, message: updated.status === 'sent' ? 'Gửi lại email thành công' : 'Gửi lại thất bại', data: serializeEmailLog(updated) });
});

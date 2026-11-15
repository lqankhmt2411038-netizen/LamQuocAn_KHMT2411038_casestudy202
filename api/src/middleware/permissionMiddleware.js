const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const { getAccess } = require('../services/taskService');

/**
 * Nạp công việc và kiểm tra quyền Ở BACKEND (không chỉ ẩn nút trên giao diện).
 * action: 'view' | 'updateStatus' | 'edit' | 'delete' | 'manage'
 * Gắn req.task, req.access, req.share cho controller dùng.
 */
const requireTaskAccess = (action = 'view') =>
  asyncHandler(async (req, res, next) => {
    const task = await Task.findById(req.params.id);
    if (!task) throw new ApiError(404, 'Không tìm thấy công việc');

    const share = await TaskShare.findOne({ taskId: task._id, userId: req.user._id });
    const access = getAccess(task, req.user._id, share);

    // Không có quyền xem -> trả 404 để không lộ việc công việc có tồn tại
    if (!access.can.view) throw new ApiError(404, 'Không tìm thấy công việc');
    if (!access.can[action]) throw new ApiError(403, 'Bạn không có quyền thực hiện thao tác này');

    req.task = task;
    req.access = access;
    req.share = share;
    next();
  });

module.exports = { requireTaskAccess };

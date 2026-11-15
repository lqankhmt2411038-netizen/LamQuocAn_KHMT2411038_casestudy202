const TaskShare = require('../models/TaskShare');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const templates = require('../utils/emailTemplates');
const { resolveUsers } = require('../utils/userResolver');
const { notifyUsers } = require('../services/notificationService');
const { logActivity } = require('../services/taskService');
const { serializeShare } = require('../utils/serializers');
const { USER_FIELDS } = require('../utils/constants');
const { idOf } = require('../utils/helpers');

const loadShares = async (taskId) => {
  const shares = await TaskShare.find({ taskId })
    .sort({ createdAt: 1 })
    .populate('userId', USER_FIELDS)
    .populate('sharedBy', USER_FIELDS);
  return shares.map(serializeShare);
};

// GET /tasks/:id/shares
exports.list = asyncHandler(async (req, res) => {
  res.json({ success: true, data: await loadShares(req.task._id) });
});

// POST /tasks/:id/shares   body: { userIds?: [], emails?: [], permission: 'viewer'|'editor' }
exports.create = asyncHandler(async (req, res) => {
  const task = req.task;
  const actor = req.user;
  const permission = req.body.permission || 'viewer';
  const users = await resolveUsers(req.body);

  const ownerId = String(idOf(task.createdBy));
  const targets = users.filter((u) => String(u._id) !== ownerId);
  if (!targets.length) throw new ApiError(400, 'Không thể chia sẻ công việc cho chính người tạo');

  for (const u of targets) {
    const existing = await TaskShare.findOne({ taskId: task._id, userId: u._id });

    if (existing) {
      if (existing.permission !== permission) {
        existing.permission = permission;
        await existing.save();
        await logActivity(task._id, actor._id, 'share_permission_changed', { userId: String(u._id), permission });
        await notifyUsers({
          task,
          userIds: [u._id],
          type: 'share_permission_changed',
          title: 'Quyền truy cập thay đổi',
          message: `${actor.fullName} đổi quyền của bạn trên "${task.title}" thành ${permission === 'editor' ? 'chỉnh sửa' : 'chỉ xem'}.`,
        });
      }
      continue;
    }

    await TaskShare.create({ taskId: task._id, userId: u._id, permission, sharedBy: actor._id });
    await logActivity(task._id, actor._id, 'shared', { userId: String(u._id), email: u.email, permission });
    await notifyUsers({
      task,
      userIds: [u._id],
      type: 'task_shared',
      title: 'Bạn được mời tham gia công việc',
      message: `${actor.fullName} đã chia sẻ "${task.title}" cho bạn (${permission === 'editor' ? 'chỉnh sửa' : 'chỉ xem'}).`,
      buildEmail: (recipient) => templates.taskShared({ task, actor, recipient, permission }),
    });
  }

  res.status(201).json({ success: true, message: 'Chia sẻ công việc thành công', data: await loadShares(task._id) });
});

// PATCH /tasks/:id/shares/:shareId   body: { permission }
exports.update = asyncHandler(async (req, res) => {
  const share = await TaskShare.findOne({ _id: req.params.shareId, taskId: req.task._id });
  if (!share) throw new ApiError(404, 'Không tìm thấy bản ghi chia sẻ');

  if (share.permission !== req.body.permission) {
    share.permission = req.body.permission;
    await share.save();
    await logActivity(req.task._id, req.user._id, 'share_permission_changed', {
      userId: String(share.userId),
      permission: share.permission,
    });
    await notifyUsers({
      task: req.task,
      userIds: [share.userId],
      type: 'share_permission_changed',
      title: 'Quyền truy cập thay đổi',
      message: `${req.user.fullName} đổi quyền của bạn trên "${req.task.title}" thành ${share.permission === 'editor' ? 'chỉnh sửa' : 'chỉ xem'}.`,
    });
  }

  res.json({ success: true, message: 'Đã cập nhật quyền', data: await loadShares(req.task._id) });
});

// DELETE /tasks/:id/shares/:shareId
exports.remove = asyncHandler(async (req, res) => {
  const share = await TaskShare.findOne({ _id: req.params.shareId, taskId: req.task._id });
  if (!share) throw new ApiError(404, 'Không tìm thấy bản ghi chia sẻ');

  await share.deleteOne();
  await logActivity(req.task._id, req.user._id, 'share_revoked', { userId: String(share.userId) });
  await notifyUsers({
    task: req.task,
    userIds: [share.userId],
    type: 'share_revoked',
    title: 'Quyền truy cập bị thu hồi',
    message: `${req.user.fullName} đã thu hồi quyền truy cập của bạn vào "${req.task.title}".`,
  });

  res.json({ success: true, message: 'Đã thu hồi quyền chia sẻ', data: await loadShares(req.task._id) });
});

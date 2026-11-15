const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const templates = require('../utils/emailTemplates');
const { resolveUsers } = require('../utils/userResolver');
const { notifyUsers } = require('../services/notificationService');
const { logActivity, populateTask } = require('../services/taskService');
const { serializeTask, userRef } = require('../utils/serializers');
const { idOf } = require('../utils/helpers');

// GET /tasks/:id/assignees
exports.list = asyncHandler(async (req, res) => {
  await populateTask(req.task);
  res.json({
    success: true,
    data: {
      primaryAssignee: userRef(req.task.primaryAssigneeId),
      assignees: req.task.assigneeIds.map(userRef),
    },
  });
});

// POST /tasks/:id/assignees   body: { userIds?: [], emails?: [], primaryAssigneeId? }
exports.assign = asyncHandler(async (req, res) => {
  const task = req.task;
  const actor = req.user;
  const users = await resolveUsers(req.body);

  const existing = new Set(task.assigneeIds.map((a) => String(idOf(a))));
  const added = users.filter((u) => !existing.has(String(u._id)));
  added.forEach((u) => task.assigneeIds.push(u._id));

  const allIds = new Set(task.assigneeIds.map((a) => String(idOf(a))));
  const { primaryAssigneeId } = req.body;
  if (primaryAssigneeId) {
    if (!allIds.has(String(primaryAssigneeId))) {
      throw new ApiError(400, 'Người phụ trách chính phải nằm trong danh sách được giao');
    }
    task.primaryAssigneeId = primaryAssigneeId;
  } else if (!task.primaryAssigneeId) {
    task.primaryAssigneeId = (added[0] || users[0])._id;
  }

  await task.save();

  for (const u of added) {
    await logActivity(task._id, actor._id, 'assigned', { userId: String(u._id), email: u.email });
  }

  // Không gửi thông báo cho chính người giao việc
  const toNotify = added.filter((u) => String(u._id) !== String(actor._id)).map((u) => u._id);
  await notifyUsers({
    task,
    userIds: toNotify,
    type: 'task_assigned',
    title: 'Bạn được giao công việc mới',
    message: `${actor.fullName} đã giao cho bạn công việc "${task.title}".`,
    buildEmail: (recipient) => templates.taskAssigned({ task, actor, recipient }),
  });

  await populateTask(task);
  res.status(added.length ? 201 : 200).json({
    success: true,
    message: added.length ? 'Giao việc thành công' : 'Những người này đã được giao trước đó',
    data: serializeTask(task, req.access),
  });
});

// PATCH /tasks/:id/assignees/:userId   body: { isPrimary: true }
exports.setPrimary = asyncHandler(async (req, res) => {
  const task = req.task;
  const { userId } = req.params;

  if (!task.assigneeIds.some((a) => String(idOf(a)) === userId)) {
    throw new ApiError(404, 'Người này chưa được giao công việc');
  }

  if (String(task.primaryAssigneeId) !== userId) {
    task.primaryAssigneeId = userId;
    await task.save();
    await logActivity(task._id, req.user._id, 'primary_changed', { userId });
    if (userId !== String(req.user._id)) {
      await notifyUsers({
        task,
        userIds: [userId],
        type: 'primary_assigned',
        title: 'Bạn là người phụ trách chính',
        message: `${req.user.fullName} chỉ định bạn phụ trách chính công việc "${task.title}".`,
      });
    }
  }

  await populateTask(task);
  res.json({ success: true, message: 'Đã cập nhật người phụ trách chính', data: serializeTask(task, req.access) });
});

// DELETE /tasks/:id/assignees/:userId
exports.unassign = asyncHandler(async (req, res) => {
  const task = req.task;
  const { userId } = req.params;

  const before = task.assigneeIds.length;
  task.assigneeIds = task.assigneeIds.filter((a) => String(idOf(a)) !== userId);
  if (task.assigneeIds.length === before) throw new ApiError(404, 'Người này chưa được giao công việc');

  if (String(task.primaryAssigneeId) === userId) {
    task.primaryAssigneeId = task.assigneeIds[0] || null;
  }
  await task.save();

  await logActivity(task._id, req.user._id, 'unassigned', { userId });
  if (userId !== String(req.user._id)) {
    await notifyUsers({
      task,
      userIds: [userId],
      type: 'task_unassigned',
      title: 'Bạn không còn được giao công việc',
      message: `${req.user.fullName} đã hủy giao công việc "${task.title}" cho bạn.`,
    });
  }

  await populateTask(task);
  res.json({ success: true, message: 'Đã hủy giao việc', data: serializeTask(task, req.access) });
});

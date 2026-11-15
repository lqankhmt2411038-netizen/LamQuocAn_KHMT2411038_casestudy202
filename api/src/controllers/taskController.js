const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const TaskActivity = require('../models/TaskActivity');
const Notification = require('../models/Notification');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const templates = require('../utils/emailTemplates');
const { notifyUsers } = require('../services/notificationService');
const {
  TASK_POPULATE,
  getAccess,
  buildAccessFilter,
  logActivity,
  getParticipantIds,
  populateTask,
} = require('../services/taskService');
const { serializeTask, serializeActivity } = require('../utils/serializers');
const { escapeRegex, parseDate, sameTime, formatDateVN, isObjectId } = require('../utils/helpers');
const { STATUS_LABELS, PRIORITY_LABELS } = require('../utils/constants');

const PRIORITY_RANK = { low: 1, medium: 2, high: 3 };

function sortTasks(tasks, sortBy, order) {
  const dir = order === 'asc' ? 1 : -1;
  const key = (t) => {
    if (sortBy === 'dueDate') return t.dueDate ? t.dueDate.getTime() : null;
    if (sortBy === 'priority') return PRIORITY_RANK[t.priority];
    return t.createdAt.getTime();
  };
  return tasks.sort((a, b) => {
    const ka = key(a);
    const kb = key(b);
    if (ka === null && kb === null) return 0;
    if (ka === null) return 1; // không có hạn -> luôn xếp cuối
    if (kb === null) return -1;
    return (ka - kb) * dir;
  });
}

// Thông báo sau khi đổi trạng thái
async function afterStatusChange({ task, actor, from, to }) {
  await logActivity(task._id, actor._id, 'status_changed', { from, to });
  const recipients = await getParticipantIds(task, actor._id);

  if (to === 'completed') {
    await notifyUsers({
      task,
      userIds: recipients,
      type: 'task_completed',
      title: 'Công việc đã hoàn thành',
      message: `${actor.fullName} đã hoàn thành "${task.title}".`,
      buildEmail: (recipient) => templates.taskCompleted({ task, actor, recipient }),
    });
  } else {
    await notifyUsers({
      task,
      userIds: recipients,
      type: 'status_changed',
      title: 'Trạng thái công việc thay đổi',
      message: `${actor.fullName} chuyển "${task.title}" sang "${STATUS_LABELS[to]}".`,
    });
  }
}

// GET /tasks
exports.list = asyncHandler(async (req, res) => {
  const me = req.user._id;
  const { scope, status, priority, q, assigneeId, sortBy = 'createdAt', order = 'desc' } = req.query;

  if (scope && !['created', 'assigned', 'shared', 'delegated'].includes(scope)) {
    throw new ApiError(400, 'scope không hợp lệ');
  }
  if (status && !Object.keys(STATUS_LABELS).includes(status)) throw new ApiError(400, 'status không hợp lệ');
  if (priority && !Object.keys(PRIORITY_LABELS).includes(priority)) throw new ApiError(400, 'priority không hợp lệ');
  if (assigneeId && !isObjectId(String(assigneeId))) throw new ApiError(400, 'assigneeId không hợp lệ');
  if (!['dueDate', 'priority', 'createdAt'].includes(sortBy)) throw new ApiError(400, 'sortBy không hợp lệ');

  const { filter: accessFilter, shares, sharedIds } = await buildAccessFilter(me);
  const and = [accessFilter];

  if (scope === 'created') and.push({ createdBy: me });
  else if (scope === 'assigned') and.push({ assigneeIds: me });
  else if (scope === 'shared') and.push({ _id: { $in: sharedIds } });
  else if (scope === 'delegated') and.push({ createdBy: me, assigneeIds: { $elemMatch: { $ne: me } } });

  if (status) and.push({ status });
  if (priority) and.push({ priority });
  if (q && String(q).trim()) and.push({ title: { $regex: escapeRegex(String(q).trim()), $options: 'i' } });
  if (assigneeId) and.push({ $or: [{ assigneeIds: assigneeId }, { primaryAssigneeId: assigneeId }] });

  const tasks = await Task.find({ $and: and }).populate(TASK_POPULATE);
  sortTasks(tasks, sortBy, order === 'asc' ? 'asc' : 'desc');

  const shareMap = new Map(shares.map((s) => [String(s.taskId), s]));
  const data = tasks.map((t) => serializeTask(t, getAccess(t, me, shareMap.get(String(t._id)))));
  res.json({ success: true, data });
});

// POST /tasks
exports.create = asyncHandler(async (req, res) => {
  const { title, description, startDate, dueDate, priority, status } = req.body;
  const start = parseDate(startDate);
  const due = parseDate(dueDate);
  if (start && due && due < start) throw new ApiError(400, 'Hạn hoàn thành phải sau ngày bắt đầu');

  const task = await Task.create({
    title,
    description: description || '',
    startDate: start || null,
    dueDate: due || null,
    priority: priority || 'medium',
    status: status || 'todo',
    createdBy: req.user._id,
  });

  await logActivity(task._id, req.user._id, 'created', { title: task.title });
  await populateTask(task);
  res.status(201).json({
    success: true,
    message: 'Tạo công việc thành công',
    data: serializeTask(task, getAccess(task, req.user._id, null)),
  });
});

// GET /tasks/:id
exports.getOne = asyncHandler(async (req, res) => {
  await populateTask(req.task);
  res.json({ success: true, data: serializeTask(req.task, req.access) });
});

// PUT /tasks/:id
exports.update = asyncHandler(async (req, res) => {
  const task = req.task;
  const actor = req.user;
  const body = req.body;
  const oldStatus = task.status;
  const changes = [];

  const track = (field, label, oldVal, newVal, fmt = (v) => v) => {
    changes.push({ field, label, from: fmt(oldVal), to: fmt(newVal) });
  };

  if (body.title !== undefined && body.title !== task.title) {
    track('title', 'Tên công việc', task.title, body.title);
    task.title = body.title;
  }
  if (body.description !== undefined && (body.description || '') !== task.description) {
    track('description', 'Mô tả', task.description || '(trống)', body.description || '(trống)');
    task.description = body.description || '';
  }
  if (body.startDate !== undefined) {
    const v = parseDate(body.startDate);
    if (!sameTime(v, task.startDate)) {
      track('startDate', 'Ngày bắt đầu', task.startDate, v, formatDateVN);
      task.startDate = v;
    }
  }
  let dueChanged = false;
  if (body.dueDate !== undefined) {
    const v = parseDate(body.dueDate);
    if (!sameTime(v, task.dueDate)) {
      track('dueDate', 'Hạn hoàn thành', task.dueDate, v, formatDateVN);
      task.dueDate = v;
      dueChanged = true;
    }
  }
  if (body.priority !== undefined && body.priority !== task.priority) {
    track('priority', 'Mức ưu tiên', PRIORITY_LABELS[task.priority], PRIORITY_LABELS[body.priority]);
    task.priority = body.priority;
  }

  if (task.startDate && task.dueDate && task.dueDate < task.startDate) {
    throw new ApiError(400, 'Hạn hoàn thành phải sau ngày bắt đầu');
  }

  const statusChanged = body.status !== undefined && body.status !== oldStatus;
  if (statusChanged) task.status = body.status;

  // Đổi hạn hoặc mở lại công việc -> cho phép nhắc việc lại
  if (dueChanged || (statusChanged && oldStatus === 'completed')) task.reminderSentAt = null;

  await task.save();

  if (changes.length) {
    await logActivity(task._id, actor._id, 'updated', { changes });

    const important = changes.some((c) => ['title', 'startDate', 'dueDate', 'priority'].includes(c.field));
    const recipients = await getParticipantIds(task, actor._id);
    const labels = changes.map((c) => c.label).join(', ');
    await notifyUsers({
      task,
      userIds: recipients,
      type: 'task_updated',
      title: 'Công việc được cập nhật',
      message: `${actor.fullName} đã cập nhật "${task.title}" (${labels}).`,
      // Chỉ gửi email khi thay đổi thông tin quan trọng (tên, ngày, hạn, ưu tiên)
      buildEmail: important
        ? (recipient) => templates.taskUpdated({ task, actor, recipient, changes })
        : undefined,
    });
  }

  if (statusChanged) await afterStatusChange({ task, actor, from: oldStatus, to: task.status });

  await populateTask(task);
  res.json({ success: true, message: 'Cập nhật công việc thành công', data: serializeTask(task, req.access) });
});

// PATCH /tasks/:id/status
exports.updateStatus = asyncHandler(async (req, res) => {
  const task = req.task;
  const from = task.status;
  const to = req.body.status;

  if (from !== to) {
    task.status = to;
    if (from === 'completed') task.reminderSentAt = null;
    await task.save();
    await afterStatusChange({ task, actor: req.user, from, to });
  }

  await populateTask(task);
  res.json({ success: true, message: 'Cập nhật trạng thái thành công', data: serializeTask(task, req.access) });
});

// DELETE /tasks/:id   (chỉ người tạo)
exports.remove = asyncHandler(async (req, res) => {
  const taskId = req.task._id;
  await Promise.all([
    TaskShare.deleteMany({ taskId }),
    Notification.deleteMany({ taskId }),
    TaskActivity.deleteMany({ taskId }),
  ]);
  await req.task.deleteOne();
  res.json({ success: true, message: 'Đã xóa công việc' });
});

// GET /tasks/:id/activities
exports.activities = asyncHandler(async (req, res) => {
  const items = await TaskActivity.find({ taskId: req.task._id })
    .sort({ createdAt: -1 })
    .limit(100)
    .populate('userId', 'fullName email avatarUrl');
  res.json({ success: true, data: items.map(serializeActivity) });
});

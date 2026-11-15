const Task = require('../models/Task');
const asyncHandler = require('../utils/asyncHandler');
const { buildAccessFilter } = require('../services/taskService');

const brief = (t) => ({
  id: String(t._id),
  title: t.title,
  dueDate: t.dueDate,
  status: t.status,
  priority: t.priority,
});

// GET /statistics/tasks
exports.tasks = asyncHandler(async (req, res) => {
  const { filter } = await buildAccessFilter(req.user._id);
  const [total, todo, inProgress, completed] = await Promise.all([
    Task.countDocuments(filter),
    Task.countDocuments({ $and: [filter, { status: 'todo' }] }),
    Task.countDocuments({ $and: [filter, { status: 'in_progress' }] }),
    Task.countDocuments({ $and: [filter, { status: 'completed' }] }),
  ]);
  res.json({ success: true, data: { total, todo, in_progress: inProgress, completed } });
});

// GET /statistics/assignments
exports.assignments = asyncHandler(async (req, res) => {
  const me = req.user._id;
  const { sharedIds } = await buildAccessFilter(me);
  const [assignedToMe, primaryAssignee, delegatedByMe, created, shared] = await Promise.all([
    Task.countDocuments({ assigneeIds: me }),
    Task.countDocuments({ primaryAssigneeId: me }),
    Task.countDocuments({ createdBy: me, assigneeIds: { $elemMatch: { $ne: me } } }),
    Task.countDocuments({ createdBy: me }),
    Task.countDocuments({ _id: { $in: sharedIds } }),
  ]);
  res.json({ success: true, data: { assignedToMe, primaryAssignee, delegatedByMe, created, shared } });
});

// GET /statistics/deadlines?hours=72
exports.deadlines = asyncHandler(async (req, res) => {
  const hours = Math.min(Math.max(Number(req.query.hours) || 72, 1), 24 * 30);
  const { filter } = await buildAccessFilter(req.user._id);
  const now = new Date();
  const limit = new Date(now.getTime() + hours * 3600 * 1000);

  const [dueSoon, overdue] = await Promise.all([
    Task.find({ $and: [filter, { status: { $ne: 'completed' }, dueDate: { $gte: now, $lte: limit } }] })
      .sort({ dueDate: 1 })
      .limit(50),
    Task.find({ $and: [filter, { status: { $ne: 'completed' }, dueDate: { $lt: now } }] })
      .sort({ dueDate: 1 })
      .limit(50),
  ]);

  res.json({
    success: true,
    data: {
      hours,
      dueSoonCount: dueSoon.length,
      overdueCount: overdue.length,
      dueSoon: dueSoon.map(brief),
      overdue: overdue.map(brief),
    },
  });
});

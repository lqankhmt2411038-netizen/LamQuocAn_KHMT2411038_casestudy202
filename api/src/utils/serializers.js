const { idOf } = require('./helpers');

const userRef = (u) => {
  if (!u) return null;
  if (u.fullName === undefined) return { id: String(idOf(u)), fullName: '', email: '', avatarUrl: '' };
  return {
    id: String(u._id),
    fullName: u.fullName,
    email: u.email,
    avatarUrl: u.avatarUrl || '',
  };
};

const serializeUser = (u) => ({
  id: String(u._id),
  fullName: u.fullName,
  email: u.email,
  avatarUrl: u.avatarUrl || '',
  createdAt: u.createdAt,
  updatedAt: u.updatedAt,
});

const serializeTask = (task, access) => ({
  id: String(task._id),
  title: task.title,
  description: task.description,
  startDate: task.startDate,
  dueDate: task.dueDate,
  priority: task.priority,
  status: task.status,
  createdAt: task.createdAt,
  updatedAt: task.updatedAt,
  createdBy: userRef(task.createdBy),
  assignees: (task.assigneeIds || []).map(userRef),
  primaryAssignee: userRef(task.primaryAssigneeId),
  myRole: access ? access.role : null,
  permissions: access ? access.can : null,
  isOverdue: !!(task.dueDate && task.status !== 'completed' && task.dueDate.getTime() < Date.now()),
});

const serializeShare = (s) => ({
  id: String(s._id),
  taskId: String(idOf(s.taskId)),
  user: userRef(s.userId),
  permission: s.permission,
  sharedBy: userRef(s.sharedBy),
  createdAt: s.createdAt,
});

const serializeNotification = (n) => ({
  id: String(n._id),
  taskId: n.taskId ? String(n.taskId) : null,
  type: n.type,
  title: n.title,
  message: n.message,
  isRead: n.isRead,
  createdAt: n.createdAt,
});

const serializeActivity = (a) => ({
  id: String(a._id),
  taskId: String(idOf(a.taskId)),
  user: userRef(a.userId),
  action: a.action,
  details: a.details || {},
  createdAt: a.createdAt,
});

const serializeEmailLog = (l) => ({
  id: String(l._id),
  taskId: l.taskId ? String(l.taskId) : null,
  recipientEmail: l.recipientEmail,
  eventType: l.eventType,
  subject: l.subject,
  status: l.status,
  attempts: l.attempts,
  errorMessage: l.errorMessage || '',
  sentAt: l.sentAt,
  createdAt: l.createdAt,
});

module.exports = {
  userRef,
  serializeUser,
  serializeTask,
  serializeShare,
  serializeNotification,
  serializeActivity,
  serializeEmailLog,
};

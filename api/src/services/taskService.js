const Task = require('../models/Task');
const TaskShare = require('../models/TaskShare');
const TaskActivity = require('../models/TaskActivity');
const { idOf } = require('../utils/helpers');
const { USER_FIELDS } = require('../utils/constants');

const TASK_POPULATE = [
  { path: 'createdBy', select: USER_FIELDS },
  { path: 'assigneeIds', select: USER_FIELDS },
  { path: 'primaryAssigneeId', select: USER_FIELDS },
];

/**
 * Tính quyền của 1 người trên 1 công việc. Nếu một người có nhiều vai trò
 * (vừa được giao vừa được chia sẻ) thì lấy quyền cao nhất:
 *   owner > editor > assignee > viewer
 *
 *  - view         : xem công việc
 *  - updateStatus : đổi trạng thái (owner, editor, assignee)
 *  - edit         : sửa thông tin (owner, editor)
 *  - delete       : xóa công việc (chỉ owner)
 *  - manage       : giao việc / quản lý chia sẻ (chỉ owner)
 */
function getAccess(task, userId, share) {
  const uid = String(userId);
  const isOwner = String(idOf(task.createdBy)) === uid;
  const isAssignee = (task.assigneeIds || []).some((a) => String(idOf(a)) === uid);
  const shareRole = share ? share.permission : null;

  let role = null;
  if (isOwner) role = 'owner';
  else if (shareRole === 'editor') role = 'editor';
  else if (isAssignee) role = 'assignee';
  else if (shareRole === 'viewer') role = 'viewer';

  return {
    role,
    can: {
      view: role !== null,
      updateStatus: ['owner', 'editor', 'assignee'].includes(role),
      edit: ['owner', 'editor'].includes(role),
      delete: role === 'owner',
      manage: role === 'owner',
    },
  };
}

// Điều kiện Mongo: công việc mà user được phép truy cập
async function buildAccessFilter(userId) {
  const shares = await TaskShare.find({ userId }).select('taskId permission');
  const sharedIds = shares.map((s) => s.taskId);
  return {
    filter: { $or: [{ createdBy: userId }, { assigneeIds: userId }, { _id: { $in: sharedIds } }] },
    shares,
    sharedIds,
  };
}

async function logActivity(taskId, userId, action, details = {}) {
  try {
    await TaskActivity.create({ taskId, userId, action, details });
  } catch (err) {
    console.error('Lỗi ghi lịch sử hoạt động:', err.message);
  }
}

// Người tạo + người được giao + người được chia sẻ (trừ excludeUserId)
async function getParticipantIds(task, excludeUserId) {
  const shares = await TaskShare.find({ taskId: task._id }).select('userId');
  const set = new Set([
    String(idOf(task.createdBy)),
    ...(task.assigneeIds || []).map((a) => String(idOf(a))),
    ...shares.map((s) => String(s.userId)),
  ]);
  if (excludeUserId) set.delete(String(excludeUserId));
  return [...set];
}

async function populateTask(task) {
  await task.populate(TASK_POPULATE);
  return task;
}

module.exports = {
  TASK_POPULATE,
  getAccess,
  buildAccessFilter,
  logActivity,
  getParticipantIds,
  populateTask,
  Task,
};

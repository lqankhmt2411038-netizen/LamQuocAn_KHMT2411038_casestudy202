const mongoose = require('mongoose');
const { PERMISSIONS } = require('../utils/constants');

const { ObjectId } = mongoose.Schema.Types;

const taskShareSchema = new mongoose.Schema(
  {
    taskId: { type: ObjectId, ref: 'Task', required: true },
    userId: { type: ObjectId, ref: 'User', required: true },
    permission: { type: String, enum: PERMISSIONS, default: 'viewer' },
    sharedBy: { type: ObjectId, ref: 'User', required: true },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

// Mỗi người chỉ có 1 bản ghi chia sẻ cho 1 công việc
taskShareSchema.index({ taskId: 1, userId: 1 }, { unique: true });
taskShareSchema.index({ userId: 1 });

module.exports = mongoose.model('TaskShare', taskShareSchema);

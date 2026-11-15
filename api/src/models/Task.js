const mongoose = require('mongoose');
const { PRIORITIES, STATUSES } = require('../utils/constants');

const { ObjectId } = mongoose.Schema.Types;

const taskSchema = new mongoose.Schema(
  {
    title: { type: String, required: [true, 'Tên công việc là bắt buộc'], trim: true, maxlength: 200 },
    description: { type: String, default: '', trim: true, maxlength: 5000 },
    createdBy: { type: ObjectId, ref: 'User', required: true },
    assigneeIds: { type: [{ type: ObjectId, ref: 'User' }], default: [] },
    primaryAssigneeId: { type: ObjectId, ref: 'User', default: null },
    startDate: { type: Date, default: null },
    dueDate: { type: Date, default: null },
    priority: { type: String, enum: PRIORITIES, default: 'medium' },
    status: { type: String, enum: STATUSES, default: 'todo' },
    // Bổ sung ngoài đề: đánh dấu đã gửi nhắc việc để không nhắc trùng
    reminderSentAt: { type: Date, default: null },
  },
  { timestamps: true }
);

taskSchema.index({ createdBy: 1 });
taskSchema.index({ assigneeIds: 1 });
taskSchema.index({ dueDate: 1, status: 1 });

module.exports = mongoose.model('Task', taskSchema);

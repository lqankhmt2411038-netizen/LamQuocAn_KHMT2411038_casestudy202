const mongoose = require('mongoose');

const { ObjectId } = mongoose.Schema.Types;

const notificationSchema = new mongoose.Schema(
  {
    userId: { type: ObjectId, ref: 'User', required: true },
    taskId: { type: ObjectId, ref: 'Task', default: null },
    type: { type: String, required: true },
    title: { type: String, required: true },
    message: { type: String, default: '' },
    isRead: { type: Boolean, default: false },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ taskId: 1 });

module.exports = mongoose.model('Notification', notificationSchema);

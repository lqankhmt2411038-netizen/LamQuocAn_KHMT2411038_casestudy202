const mongoose = require('mongoose');

const { ObjectId } = mongoose.Schema.Types;

const emailLogSchema = new mongoose.Schema(
  {
    taskId: { type: ObjectId, ref: 'Task', default: null },
    recipientEmail: { type: String, required: true },
    eventType: { type: String, required: true },
    subject: { type: String, required: true },
    status: { type: String, enum: ['pending', 'sent', 'failed'], default: 'pending' },
    attempts: { type: Number, default: 0 },
    errorMessage: { type: String, default: '' },
    sentAt: { type: Date, default: null },
    // Nội dung email lưu để có thể thử gửi lại; không trả ra API
    htmlBody: { type: String, select: false },
    textBody: { type: String, select: false },
  },
  { timestamps: { createdAt: true, updatedAt: false } }
);

emailLogSchema.index({ taskId: 1, createdAt: -1 });

module.exports = mongoose.model('EmailLog', emailLogSchema);

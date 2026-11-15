const cron = require('node-cron');
const Task = require('../models/Task');
const { notifyUsers } = require('./notificationService');
const templates = require('../utils/emailTemplates');
const { idOf } = require('../utils/helpers');

let running = false;

// Tìm công việc chưa hoàn thành, còn <= REMINDER_HOURS giờ nữa là đến hạn và chưa được nhắc
async function runReminderCheck() {
  if (running) return;
  running = true;
  try {
    const hours = Number(process.env.REMINDER_HOURS) || 24;
    const now = new Date();
    const limit = new Date(now.getTime() + hours * 3600 * 1000);

    const tasks = await Task.find({
      status: { $ne: 'completed' },
      dueDate: { $gt: now, $lte: limit },
      reminderSentAt: null,
    });

    for (const task of tasks) {
      // Đánh dấu trước (nguyên tử) để tránh nhắc trùng nếu có 2 tiến trình chạy cùng lúc
      const claimed = await Task.findOneAndUpdate(
        { _id: task._id, reminderSentAt: null },
        { $set: { reminderSentAt: new Date() } }
      );
      if (!claimed) continue;

      const recipients = task.assigneeIds.length
        ? task.assigneeIds.map((a) => String(idOf(a)))
        : [String(task.createdBy)];

      await notifyUsers({
        task,
        userIds: recipients,
        type: 'due_reminder',
        title: 'Công việc sắp đến hạn',
        message: `"${task.title}" sắp đến hạn hoàn thành.`,
        buildEmail: (recipient) => templates.dueReminder({ task, recipient }),
      });
    }
    if (tasks.length) console.log(`⏰ Đã nhắc việc cho ${tasks.length} công việc`);
  } catch (err) {
    console.error('Lỗi tác vụ nhắc việc:', err.message);
  } finally {
    running = false;
  }
}

function startReminderJob() {
  if (String(process.env.ENABLE_REMINDER).toLowerCase() === 'false') {
    console.log('⏰ Nhắc việc tự động: TẮT');
    return;
  }
  const expr = process.env.REMINDER_CRON || '*/15 * * * *';
  if (!cron.validate(expr)) {
    console.error('REMINDER_CRON không hợp lệ:', expr);
    return;
  }
  cron.schedule(expr, runReminderCheck);
  console.log(`⏰ Nhắc việc tự động: BẬT (${expr})`);
}

module.exports = { startReminderJob, runReminderCheck };

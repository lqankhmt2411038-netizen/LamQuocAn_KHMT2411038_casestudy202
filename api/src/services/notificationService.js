const Notification = require('../models/Notification');
const User = require('../models/User');
const { queueEmail } = require('./emailService');

/**
 * Tạo thông báo trong ứng dụng (+ email nếu có buildEmail) cho danh sách người nhận.
 * Lỗi của từng người nhận được ghi log, không làm hỏng thao tác chính.
 */
async function notifyUsers({ task, userIds, type, title, message, buildEmail }) {
  const ids = [...new Set((userIds || []).map(String))];
  if (!ids.length) return;
  const users = await User.find({ _id: { $in: ids } });

  await Promise.all(
    users.map(async (u) => {
      try {
        await Notification.create({ userId: u._id, taskId: task._id, type, title, message });
        if (buildEmail) {
          await queueEmail({
            taskId: task._id,
            to: u.email,
            eventType: type,
            template: buildEmail(u),
          });
        }
      } catch (err) {
        console.error('Lỗi tạo thông báo:', err.message);
      }
    })
  );
}

module.exports = { notifyUsers };

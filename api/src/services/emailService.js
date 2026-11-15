const EmailLog = require('../models/EmailLog');
const { getTransporter, getFrom } = require('../config/email');

const MAX_ATTEMPTS = () => Number(process.env.EMAIL_MAX_ATTEMPTS) || 3;

// Gửi 1 email theo log. Chỉ gửi khi log đang ở trạng thái 'pending' -> tránh gửi trùng.
async function deliver(logId) {
  const log = await EmailLog.findById(logId).select('+htmlBody +textBody');
  if (!log || log.status !== 'pending') return log;

  log.attempts += 1;
  try {
    const transporter = getTransporter();
    if (!transporter) throw new Error('Chưa cấu hình SMTP (SMTP_HOST / SMTP_USER / SMTP_PASS)');
    await transporter.sendMail({
      from: getFrom(),
      to: log.recipientEmail,
      subject: log.subject,
      html: log.htmlBody,
      text: log.textBody,
    });
    log.status = 'sent';
    log.sentAt = new Date();
    log.errorMessage = '';
  } catch (err) {
    log.status = 'failed';
    log.errorMessage = String((err && err.message) || err).slice(0, 500);
  }
  await log.save();
  return log;
}

// Ghi log 'pending' rồi gửi nền (không làm chậm request của người dùng)
async function queueEmail({ taskId = null, to, eventType, template }) {
  const log = await EmailLog.create({
    taskId,
    recipientEmail: to,
    eventType,
    subject: template.subject,
    htmlBody: template.html,
    textBody: template.text,
    status: 'pending',
  });
  setImmediate(() => deliver(log._id).catch((e) => console.error('Lỗi gửi email:', e.message)));
  return log;
}

// Thử gửi lại: chuyển failed -> pending theo kiểu nguyên tử rồi mới gửi
async function retryEmail(logId) {
  const log = await EmailLog.findOneAndUpdate(
    { _id: logId, status: 'failed', attempts: { $lt: MAX_ATTEMPTS() } },
    { $set: { status: 'pending' } },
    { new: true }
  );
  if (!log) return null;
  return deliver(log._id);
}

module.exports = { queueEmail, deliver, retryEmail, MAX_ATTEMPTS };

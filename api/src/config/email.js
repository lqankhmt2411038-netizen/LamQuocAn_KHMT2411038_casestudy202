const nodemailer = require('nodemailer');

let transporter = null;

// Trả về null nếu chưa cấu hình SMTP
function getTransporter() {
  const { SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS } = process.env;
  if (!SMTP_HOST || !SMTP_USER || !SMTP_PASS) return null;
  if (!transporter) {
    const port = Number(SMTP_PORT) || 587;
    transporter = nodemailer.createTransport({
      host: SMTP_HOST,
      port,
      secure: port === 465,
      auth: { user: SMTP_USER, pass: SMTP_PASS },
    });
  }
  return transporter;
}

const getFrom = () =>
  process.env.EMAIL_FROM || process.env.SMTP_USER || 'Task Manager <no-reply@example.com>';

module.exports = { getTransporter, getFrom };

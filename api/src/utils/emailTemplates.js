const { formatDateVN } = require('./helpers');
const { STATUS_LABELS, PRIORITY_LABELS } = require('./constants');

const APP_NAME = () => process.env.APP_NAME || 'Task Manager';

// Chống chèn HTML vào nội dung email
const esc = (s) =>
  String(s ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

const layout = (heading, intro, task, extraHtml = '') => `
<div style="font-family:Arial,Helvetica,sans-serif;max-width:560px;margin:0 auto;border:1px solid #e0e0e0;border-radius:10px;overflow:hidden">
  <div style="background:#3f51b5;color:#fff;padding:16px 20px;font-size:18px;font-weight:bold">${esc(APP_NAME())}</div>
  <div style="padding:20px">
    <h2 style="margin:0 0 10px;color:#222">${esc(heading)}</h2>
    <p style="color:#444;line-height:1.5">${intro}</p>
    <table style="width:100%;border-collapse:collapse;margin-top:12px;font-size:14px">
      <tr><td style="padding:6px 0;color:#777;width:130px">Công việc</td><td style="padding:6px 0"><b>${esc(task.title)}</b></td></tr>
      <tr><td style="padding:6px 0;color:#777">Hạn hoàn thành</td><td style="padding:6px 0">${esc(formatDateVN(task.dueDate))}</td></tr>
      <tr><td style="padding:6px 0;color:#777">Mức ưu tiên</td><td style="padding:6px 0">${esc(PRIORITY_LABELS[task.priority] || task.priority)}</td></tr>
      <tr><td style="padding:6px 0;color:#777">Trạng thái</td><td style="padding:6px 0">${esc(STATUS_LABELS[task.status] || task.status)}</td></tr>
    </table>
    ${extraHtml}
    <p style="color:#999;font-size:12px;margin-top:24px">Email được gửi tự động từ hệ thống, vui lòng không trả lời.</p>
  </div>
</div>`;

const plain = (lines) => lines.filter(Boolean).join('\n');

exports.taskAssigned = ({ task, actor, recipient }) => ({
  subject: `[${APP_NAME()}] Bạn được giao công việc: ${task.title}`,
  html: layout(
    'Bạn được giao một công việc mới',
    `Xin chào <b>${esc(recipient.fullName)}</b>, <b>${esc(actor.fullName)}</b> vừa giao công việc cho bạn.`,
    task
  ),
  text: plain([
    `Xin chào ${recipient.fullName},`,
    `${actor.fullName} vừa giao công việc cho bạn: ${task.title}`,
    `Hạn hoàn thành: ${formatDateVN(task.dueDate)}`,
  ]),
});

exports.taskShared = ({ task, actor, recipient, permission }) => {
  const perm = permission === 'editor' ? 'chỉnh sửa' : 'chỉ xem';
  return {
    subject: `[${APP_NAME()}] ${actor.fullName} đã chia sẻ công việc với bạn: ${task.title}`,
    html: layout(
      'Bạn được mời tham gia một công việc',
      `Xin chào <b>${esc(recipient.fullName)}</b>, <b>${esc(actor.fullName)}</b> đã chia sẻ công việc với bạn. Quyền của bạn: <b>${esc(perm)}</b>.`,
      task
    ),
    text: plain([
      `Xin chào ${recipient.fullName},`,
      `${actor.fullName} đã chia sẻ công việc "${task.title}" với bạn (quyền: ${perm}).`,
    ]),
  };
};

exports.taskUpdated = ({ task, actor, recipient, changes }) => {
  const rows = changes
    .map(
      (c) =>
        `<li><b>${esc(c.label)}</b>: ${esc(c.from)} &rarr; <b>${esc(c.to)}</b></li>`
    )
    .join('');
  return {
    subject: `[${APP_NAME()}] Công việc "${task.title}" vừa được cập nhật`,
    html: layout(
      'Thông tin công việc đã thay đổi',
      `Xin chào <b>${esc(recipient.fullName)}</b>, <b>${esc(actor.fullName)}</b> vừa cập nhật công việc.`,
      task,
      `<ul style="margin-top:14px;color:#444;line-height:1.6">${rows}</ul>`
    ),
    text: plain([
      `Xin chào ${recipient.fullName},`,
      `${actor.fullName} vừa cập nhật công việc "${task.title}":`,
      ...changes.map((c) => `- ${c.label}: ${c.from} -> ${c.to}`),
    ]),
  };
};

exports.taskCompleted = ({ task, actor, recipient }) => ({
  subject: `[${APP_NAME()}] Công việc đã hoàn thành: ${task.title}`,
  html: layout(
    'Công việc đã hoàn thành',
    `Xin chào <b>${esc(recipient.fullName)}</b>, <b>${esc(actor.fullName)}</b> đã đánh dấu công việc là hoàn thành.`,
    task
  ),
  text: plain([
    `Xin chào ${recipient.fullName},`,
    `${actor.fullName} đã đánh dấu hoàn thành công việc: ${task.title}`,
  ]),
});

exports.dueReminder = ({ task, recipient }) => ({
  subject: `[${APP_NAME()}] Nhắc việc sắp đến hạn: ${task.title}`,
  html: layout(
    'Công việc sắp đến hạn',
    `Xin chào <b>${esc(recipient.fullName)}</b>, công việc dưới đây sắp đến hạn hoàn thành.`,
    task
  ),
  text: plain([
    `Xin chào ${recipient.fullName},`,
    `Công việc "${task.title}" sắp đến hạn: ${formatDateVN(task.dueDate)}`,
  ]),
});

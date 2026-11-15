// Tạo dữ liệu mẫu:  npm run seed
// Chỉ xóa/tạo lại dữ liệu của 4 tài khoản demo (@example.com), không đụng dữ liệu khác.
require('dotenv').config();
const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const connectDB = require('./config/database');
const User = require('./models/User');
const Task = require('./models/Task');
const TaskShare = require('./models/TaskShare');
const Notification = require('./models/Notification');
const TaskActivity = require('./models/TaskActivity');

const DAY = 24 * 3600 * 1000;
const inDays = (d) => new Date(Date.now() + d * DAY);

(async () => {
  await connectDB();

  const demoEmails = ['an@example.com', 'binh@example.com', 'chi@example.com', 'dung@example.com'];
  const old = await User.find({ email: { $in: demoEmails } }).select('_id');
  const oldIds = old.map((u) => u._id);
  const oldTasks = await Task.find({ createdBy: { $in: oldIds } }).select('_id');
  const oldTaskIds = oldTasks.map((t) => t._id);
  await Promise.all([
    TaskShare.deleteMany({ taskId: { $in: oldTaskIds } }),
    Notification.deleteMany({ $or: [{ taskId: { $in: oldTaskIds } }, { userId: { $in: oldIds } }] }),
    TaskActivity.deleteMany({ taskId: { $in: oldTaskIds } }),
    Task.deleteMany({ _id: { $in: oldTaskIds } }),
    User.deleteMany({ _id: { $in: oldIds } }),
  ]);

  const passwordHash = await bcrypt.hash('123456', 10);
  const [an, binh, chi, dung] = await User.insertMany([
    { fullName: 'Lâm Quốc An', email: 'an@example.com', passwordHash },
    { fullName: 'Nguyễn Văn Bình', email: 'binh@example.com', passwordHash },
    { fullName: 'Trần Thị Chi', email: 'chi@example.com', passwordHash },
    { fullName: 'Phạm Minh Dũng', email: 'dung@example.com', passwordHash },
  ]);

  const tasks = await Task.insertMany([
    {
      title: 'Thiết kế giao diện màn hình đăng nhập',
      description: 'Làm giao diện login/register bằng Flutter, có kiểm tra dữ liệu nhập.',
      createdBy: an._id, assigneeIds: [binh._id, chi._id], primaryAssigneeId: binh._id,
      startDate: inDays(-3), dueDate: inDays(2), priority: 'high', status: 'in_progress',
    },
    {
      title: 'Viết API quản lý công việc',
      description: 'CRUD công việc, phân quyền viewer/editor.',
      createdBy: an._id, assigneeIds: [an._id], primaryAssigneeId: an._id,
      startDate: inDays(-5), dueDate: inDays(-1), priority: 'high', status: 'todo',
    },
    {
      title: 'Viết báo cáo case study',
      description: 'Tổng hợp chức năng, sơ đồ và hướng dẫn chạy.',
      createdBy: an._id, assigneeIds: [], primaryAssigneeId: null,
      startDate: inDays(0), dueDate: inDays(7), priority: 'medium', status: 'todo',
    },
    {
      title: 'Cấu hình gửi email SMTP',
      description: 'Dùng nodemailer, lưu lịch sử gửi.',
      createdBy: binh._id, assigneeIds: [an._id], primaryAssigneeId: an._id,
      startDate: inDays(-2), dueDate: inDays(5), priority: 'medium', status: 'in_progress',
    },
    {
      title: 'Kiểm thử tích hợp toàn hệ thống',
      description: 'Kiểm thử luồng giao việc, chia sẻ, thông báo.',
      createdBy: chi._id, assigneeIds: [dung._id], primaryAssigneeId: dung._id,
      startDate: inDays(-7), dueDate: inDays(-3), priority: 'low', status: 'completed',
    },
  ]);

  await TaskShare.insertMany([
    { taskId: tasks[4]._id, userId: an._id, permission: 'viewer', sharedBy: chi._id },
    { taskId: tasks[2]._id, userId: binh._id, permission: 'editor', sharedBy: an._id },
  ]);

  await Notification.insertMany([
    { userId: binh._id, taskId: tasks[0]._id, type: 'task_assigned', title: 'Bạn được giao công việc mới', message: 'Lâm Quốc An đã giao cho bạn công việc "Thiết kế giao diện màn hình đăng nhập".' },
    { userId: an._id, taskId: tasks[3]._id, type: 'task_assigned', title: 'Bạn được giao công việc mới', message: 'Nguyễn Văn Bình đã giao cho bạn công việc "Cấu hình gửi email SMTP".' },
    { userId: an._id, taskId: tasks[4]._id, type: 'task_shared', title: 'Bạn được mời tham gia công việc', message: 'Trần Thị Chi đã chia sẻ "Kiểm thử tích hợp toàn hệ thống" cho bạn (chỉ xem).' },
  ]);

  await TaskActivity.insertMany(tasks.map((t) => ({ taskId: t._id, userId: t.createdBy, action: 'created', details: { title: t.title } })));

  console.log('✔ Đã tạo dữ liệu mẫu. Đăng nhập bằng một trong các tài khoản (mật khẩu 123456):');
  demoEmails.forEach((e) => console.log('   -', e));
  await mongoose.disconnect();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});

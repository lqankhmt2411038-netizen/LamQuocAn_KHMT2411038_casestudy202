const { body } = require('express-validator');
const { PRIORITIES, STATUSES, PERMISSIONS } = require('../utils/constants');

const optDate = (field, label) =>
  body(field).optional({ nullable: true, checkFalsy: true }).isISO8601().withMessage(`${label} không hợp lệ`);

exports.createTask = [
  body('title')
    .isString().withMessage('Tên công việc là bắt buộc')
    .trim()
    .notEmpty().withMessage('Tên công việc là bắt buộc')
    .isLength({ max: 200 }).withMessage('Tên công việc tối đa 200 ký tự'),
  body('description').optional({ nullable: true }).isString().isLength({ max: 5000 }).withMessage('Mô tả tối đa 5000 ký tự'),
  optDate('startDate', 'Ngày bắt đầu'),
  optDate('dueDate', 'Hạn hoàn thành'),
  body('priority').optional().isIn(PRIORITIES).withMessage('Mức ưu tiên không hợp lệ'),
  body('status').optional().isIn(STATUSES).withMessage('Trạng thái không hợp lệ'),
];

exports.updateTask = [
  body('title')
    .optional()
    .isString().trim()
    .notEmpty().withMessage('Tên công việc không được để trống')
    .isLength({ max: 200 }).withMessage('Tên công việc tối đa 200 ký tự'),
  body('description').optional({ nullable: true }).isString().isLength({ max: 5000 }).withMessage('Mô tả tối đa 5000 ký tự'),
  optDate('startDate', 'Ngày bắt đầu'),
  optDate('dueDate', 'Hạn hoàn thành'),
  body('priority').optional().isIn(PRIORITIES).withMessage('Mức ưu tiên không hợp lệ'),
  body('status').optional().isIn(STATUSES).withMessage('Trạng thái không hợp lệ'),
];

exports.updateStatus = [
  body('status').isIn(STATUSES).withMessage('Trạng thái không hợp lệ'),
];

const userList = [
  body('userIds').optional().isArray({ max: 50 }).withMessage('userIds phải là mảng'),
  body('userIds.*').optional().isString().withMessage('userIds không hợp lệ'),
  body('emails').optional().isArray({ max: 50 }).withMessage('emails phải là mảng'),
  body('emails.*').optional().isString().trim().toLowerCase().isEmail().withMessage('Có email không hợp lệ'),
  body().custom((value) => {
    const n = (value.userIds?.length || 0) + (value.emails?.length || 0);
    if (n === 0) throw new Error('Vui lòng chọn ít nhất một người');
    return true;
  }),
];

exports.assign = [
  ...userList,
  body('primaryAssigneeId').optional({ nullable: true }).isString().withMessage('primaryAssigneeId không hợp lệ'),
];

exports.setPrimary = [body('isPrimary').equals('true').withMessage('Chỉ hỗ trợ isPrimary = true')];

exports.share = [
  ...userList,
  body('permission').optional().isIn(PERMISSIONS).withMessage('Quyền phải là viewer hoặc editor'),
];

exports.updateShare = [body('permission').isIn(PERMISSIONS).withMessage('Quyền phải là viewer hoặc editor')];

const { body } = require('express-validator');

const password = (field = 'password', label = 'Mật khẩu') =>
  body(field)
    .isString().withMessage(`${label} là bắt buộc`)
    .isLength({ min: 6, max: 72 }).withMessage(`${label} phải từ 6 đến 72 ký tự`);

exports.register = [
  body('fullName')
    .isString().withMessage('Họ tên là bắt buộc')
    .trim()
    .notEmpty().withMessage('Họ tên là bắt buộc')
    .isLength({ max: 100 }).withMessage('Họ tên tối đa 100 ký tự'),
  body('email').isString().withMessage('Email là bắt buộc').trim().toLowerCase().isEmail().withMessage('Email không hợp lệ'),
  password(),
];

exports.login = [
  body('email').isString().withMessage('Email là bắt buộc').trim().toLowerCase().isEmail().withMessage('Email không hợp lệ'),
  body('password').isString().notEmpty().withMessage('Mật khẩu là bắt buộc'),
];

exports.updateProfile = [
  body('fullName')
    .optional()
    .isString().withMessage('Họ tên không hợp lệ')
    .trim()
    .notEmpty().withMessage('Họ tên không được để trống')
    .isLength({ max: 100 }).withMessage('Họ tên tối đa 100 ký tự'),
  body('avatarUrl').optional().isString().isLength({ max: 500 }).withMessage('Đường dẫn ảnh quá dài'),
];

exports.changePassword = [
  body('currentPassword').isString().notEmpty().withMessage('Vui lòng nhập mật khẩu hiện tại'),
  password('newPassword', 'Mật khẩu mới'),
];

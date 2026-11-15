const { validationResult } = require('express-validator');
const ApiError = require('../utils/ApiError');
const { isObjectId } = require('../utils/helpers');

// Chạy sau các rule của express-validator
const validate = (req, res, next) => {
  const result = validationResult(req);
  if (result.isEmpty()) return next();
  const errors = result.array().map((e) => ({ field: e.path, message: e.msg }));
  return next(new ApiError(400, errors[0].message, errors));
};

// Kiểm tra các tham số đường dẫn là ObjectId hợp lệ
const validateObjectId = (...names) => (req, res, next) => {
  for (const name of names) {
    if (req.params[name] !== undefined && !isObjectId(req.params[name])) {
      return next(new ApiError(400, 'Mã định danh không hợp lệ'));
    }
  }
  next();
};

module.exports = { validate, validateObjectId };

const ApiError = require('../utils/ApiError');

const notFound = (req, res, next) => next(new ApiError(404, 'Không tìm thấy đường dẫn yêu cầu'));

// eslint-disable-next-line no-unused-vars
const errorHandler = (err, req, res, next) => {
  let status = 500;
  let message = 'Lỗi máy chủ, vui lòng thử lại sau';
  let errors;

  if (err instanceof ApiError) {
    status = err.statusCode;
    message = err.message;
    errors = err.errors;
  } else if (err.type === 'entity.parse.failed') {
    status = 400;
    message = 'Dữ liệu gửi lên không phải JSON hợp lệ';
  } else if (err.name === 'ValidationError') {
    status = 400;
    message = Object.values(err.errors)[0]?.message || 'Dữ liệu không hợp lệ';
  } else if (err.name === 'CastError') {
    status = 400;
    message = 'Dữ liệu không hợp lệ';
  } else if (err.code === 11000) {
    status = 409;
    message = 'Dữ liệu bị trùng';
  } else {
    // Chỉ ghi log phía server, không trả chi tiết lỗi cho client
    console.error('Lỗi không mong đợi:', err);
  }

  res.status(status).json({ success: false, message, ...(errors ? { errors } : {}) });
};

module.exports = { notFound, errorHandler };

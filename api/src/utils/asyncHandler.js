// Bọc controller async để lỗi được chuyển sang errorMiddleware
module.exports = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);

const User = require('../models/User');
const ApiError = require('./ApiError');
const { isObjectId } = require('./helpers');

/**
 * Chuyển { userIds, emails } thành danh sách User (không trùng).
 * Nếu có mã/email không tồn tại -> báo lỗi 404 kèm danh sách.
 */
async function resolveUsers({ userIds = [], emails = [] }) {
  const ids = [...new Set(userIds.filter(isObjectId))];
  const mails = [...new Set(emails.map((e) => String(e).trim().toLowerCase()))];
  const invalidIds = userIds.filter((i) => !isObjectId(i));

  const found = await User.find({ $or: [{ _id: { $in: ids } }, { email: { $in: mails } }] });

  const foundIds = new Set(found.map((u) => String(u._id)));
  const foundMails = new Set(found.map((u) => u.email));
  const notFound = [
    ...invalidIds,
    ...ids.filter((i) => !foundIds.has(i)),
    ...mails.filter((m) => !foundMails.has(m)),
  ];
  if (notFound.length) {
    throw new ApiError(404, `Không tìm thấy người dùng: ${notFound.join(', ')}`);
  }

  const unique = [...new Map(found.map((u) => [String(u._id), u])).values()];
  return unique;
}

module.exports = { resolveUsers };

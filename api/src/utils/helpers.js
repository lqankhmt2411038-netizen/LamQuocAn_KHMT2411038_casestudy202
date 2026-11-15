const OBJECT_ID_REGEX = /^[0-9a-fA-F]{24}$/;

const isObjectId = (v) => typeof v === 'string' && OBJECT_ID_REGEX.test(v);

// Lấy _id nếu là document đã populate, ngược lại trả chính nó
const idOf = (x) => (x && x._id ? x._id : x);

const escapeRegex = (s) => String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// '' / null -> null ; undefined -> undefined ; còn lại -> Date
const parseDate = (v) => {
  if (v === undefined) return undefined;
  if (v === null || v === '') return null;
  return new Date(v);
};

const sameTime = (a, b) => {
  const ta = a ? new Date(a).getTime() : null;
  const tb = b ? new Date(b).getTime() : null;
  return ta === tb;
};

const formatDateVN = (d) => {
  if (!d) return 'Chưa đặt';
  return new Date(d).toLocaleString('vi-VN', {
    timeZone: 'Asia/Ho_Chi_Minh',
    hour12: false,
  });
};

module.exports = { isObjectId, idOf, escapeRegex, parseDate, sameTime, formatDateVN };

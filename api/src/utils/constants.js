module.exports = {
  PRIORITIES: ['low', 'medium', 'high'],
  STATUSES: ['todo', 'in_progress', 'completed'],
  PERMISSIONS: ['viewer', 'editor'],
  SCOPES: ['created', 'assigned', 'shared', 'delegated'],
  USER_FIELDS: 'fullName email avatarUrl',
  STATUS_LABELS: {
    todo: 'Chưa thực hiện',
    in_progress: 'Đang thực hiện',
    completed: 'Đã hoàn thành',
  },
  PRIORITY_LABELS: { low: 'Thấp', medium: 'Trung bình', high: 'Cao' },
};

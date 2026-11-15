# api – Backend Task Manager

Node.js + Express + MongoDB (Mongoose). JWT, bcrypt, Nodemailer, node-cron.

## Chạy
```bash
cd api
npm install
cp .env.example .env     # Windows: copy .env.example .env  rồi sửa giá trị
npm run seed             # (tuỳ chọn) tạo dữ liệu mẫu
npm run dev              # hoặc npm start
```
Kiểm tra: http://localhost:3000/api/health

## Tài khoản mẫu (sau `npm run seed`, mật khẩu `123456`)
an@example.com • binh@example.com • chi@example.com • dung@example.com

## Mô hình phân quyền (kiểm tra ở backend)
| Vai trò | Xem | Đổi trạng thái | Sửa thông tin | Xóa | Giao việc / chia sẻ |
|---|:-:|:-:|:-:|:-:|:-:|
| owner (người tạo) | ✔ | ✔ | ✔ | ✔ | ✔ |
| editor | ✔ | ✔ | ✔ | ✘ | ✘ |
| assignee (được giao) | ✔ | ✔ | ✘ | ✘ | ✘ |
| viewer | ✔ | ✘ | ✘ | ✘ | ✘ |

Một người có nhiều vai trò → lấy quyền cao nhất (owner > editor > assignee > viewer).

## Danh sách API
Mọi API (trừ `/auth/register`, `/auth/login`, `/health`) cần header `Authorization: Bearer <token>`.
Phản hồi: `{ "success": true, "data": ... }` hoặc `{ "success": false, "message": "..." }`.

| Nhóm | Endpoint |
|---|---|
| Auth | `POST /auth/register` `POST /auth/login` `GET/PUT /auth/me` `PUT /auth/change-password` |
| Users | `GET /users/search?q=` (≥2 ký tự) `GET /users/:id` |
| Tasks | `GET /tasks` (scope, status, priority, q, assigneeId, sortBy, order) `POST /tasks` `GET/PUT/DELETE /tasks/:id` `PATCH /tasks/:id/status` `GET /tasks/:id/activities` |
| Giao việc | `GET/POST /tasks/:id/assignees` `PATCH/DELETE /tasks/:id/assignees/:userId` |
| Chia sẻ | `GET/POST /tasks/:id/shares` `PATCH/DELETE /tasks/:id/shares/:shareId` |
| Thông báo | `GET /notifications` `GET /notifications/unread-count` `PATCH /notifications/:id/read` `PATCH /notifications/read-all` |
| Thống kê | `GET /statistics/tasks` `/assignments` `/deadlines` |
| Email | `GET /tasks/:id/email-logs` `POST /email-logs/:id/retry` |

`scope`: `created` (tôi tạo) • `assigned` (giao cho tôi) • `delegated` (tôi đã giao người khác) • `shared` (được chia sẻ).
`POST /tasks/:id/assignees` và `/shares` nhận `{ "userIds": [...] }` và/hoặc `{ "emails": [...] }`.

## Ghi chú thiết kế
- Email gửi **từ backend**, ghi `email_logs` (pending → sent/failed), thử lại tối đa `EMAIL_MAX_ATTEMPTS` lần, chuyển trạng thái nguyên tử để không gửi trùng.
- Chưa cấu hình SMTP thì email ghi nhận `failed` với lý do rõ ràng, các chức năng khác vẫn chạy bình thường.
- Nhắc việc: cron mỗi 15 phút, nhắc khi còn ≤ `REMINDER_HOURS` giờ; thêm trường `reminderSentAt` trong `tasks` để không nhắc trùng (ngoài 6 collection của đề không thêm collection nào khác).
- Không commit `.env` (đã có trong `.gitignore`).

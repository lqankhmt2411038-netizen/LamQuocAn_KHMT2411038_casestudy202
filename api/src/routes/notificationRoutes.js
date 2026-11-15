const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { validateObjectId } = require('../middleware/validateMiddleware');
const c = require('../controllers/notificationController');

router.use(auth);
router.get('/', c.list);
router.get('/unread-count', c.unreadCount);
router.patch('/read-all', c.markAllRead);
router.patch('/:id/read', validateObjectId('id'), c.markRead);

module.exports = router;

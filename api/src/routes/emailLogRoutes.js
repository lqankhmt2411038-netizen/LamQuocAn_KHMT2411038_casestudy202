const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { validateObjectId } = require('../middleware/validateMiddleware');
const c = require('../controllers/emailLogController');

router.use(auth);
router.post('/:id/retry', validateObjectId('id'), c.retry);

module.exports = router;

const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { validateObjectId } = require('../middleware/validateMiddleware');
const c = require('../controllers/userController');

router.use(auth);
router.get('/search', c.search);
router.get('/:id', validateObjectId('id'), c.getById);

module.exports = router;

const router = require('express').Router({ mergeParams: true });
const { requireTaskAccess } = require('../middleware/permissionMiddleware');
const { validate, validateObjectId } = require('../middleware/validateMiddleware');
const v = require('../validators/taskValidator');
const c = require('../controllers/taskShareController');

router.get('/', validateObjectId('id'), requireTaskAccess('view'), c.list);
router.post('/', validateObjectId('id'), requireTaskAccess('manage'), v.share, validate, c.create);
router.patch('/:shareId', validateObjectId('id', 'shareId'), requireTaskAccess('manage'), v.updateShare, validate, c.update);
router.delete('/:shareId', validateObjectId('id', 'shareId'), requireTaskAccess('manage'), c.remove);

module.exports = router;

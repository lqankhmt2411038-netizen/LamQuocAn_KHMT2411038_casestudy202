const router = require('express').Router({ mergeParams: true });
const { requireTaskAccess } = require('../middleware/permissionMiddleware');
const { validate, validateObjectId } = require('../middleware/validateMiddleware');
const v = require('../validators/taskValidator');
const c = require('../controllers/assignmentController');

router.get('/', validateObjectId('id'), requireTaskAccess('view'), c.list);
router.post('/', validateObjectId('id'), requireTaskAccess('manage'), v.assign, validate, c.assign);
router.patch('/:userId', validateObjectId('id', 'userId'), requireTaskAccess('manage'), v.setPrimary, validate, c.setPrimary);
router.delete('/:userId', validateObjectId('id', 'userId'), requireTaskAccess('manage'), c.unassign);

module.exports = router;

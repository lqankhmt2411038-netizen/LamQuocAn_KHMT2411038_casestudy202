const router = require('express').Router();
const auth = require('../middleware/authMiddleware');
const { requireTaskAccess } = require('../middleware/permissionMiddleware');
const { validate, validateObjectId } = require('../middleware/validateMiddleware');
const v = require('../validators/taskValidator');
const c = require('../controllers/taskController');
const emailLogs = require('../controllers/emailLogController');
const assignmentRoutes = require('./assignmentRoutes');
const taskShareRoutes = require('./taskShareRoutes');

router.use(auth);

router.get('/', c.list);
router.post('/', v.createTask, validate, c.create);

router.get('/:id', validateObjectId('id'), requireTaskAccess('view'), c.getOne);
router.put('/:id', validateObjectId('id'), requireTaskAccess('edit'), v.updateTask, validate, c.update);
router.delete('/:id', validateObjectId('id'), requireTaskAccess('delete'), c.remove);
router.patch('/:id/status', validateObjectId('id'), requireTaskAccess('updateStatus'), v.updateStatus, validate, c.updateStatus);
router.get('/:id/activities', validateObjectId('id'), requireTaskAccess('view'), c.activities);
router.get('/:id/email-logs', validateObjectId('id'), requireTaskAccess('manage'), emailLogs.listByTask);

router.use('/:id/assignees', assignmentRoutes);
router.use('/:id/shares', taskShareRoutes);

module.exports = router;

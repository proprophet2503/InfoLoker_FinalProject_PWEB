const router = require('express').Router();
const { authMiddleware, requireRole } = require('../middleware/authMiddleware');
const c = require('../controllers/adminController');

router.use(authMiddleware, requireRole('admin'));

router.get('/users',            c.getUsers);
router.put('/users/:id/toggle', c.toggleUser);
router.get('/stats',            c.getStats);

module.exports = router;

const router = require('express').Router();
const { authMiddleware, requireRole } = require('../middleware/authMiddleware');
const c = require('../controllers/lowonganController');

router.get('/',         c.list);
router.get('/:id',      c.detail);
router.post('/',        authMiddleware, requireRole('perusahaan'), c.create);
router.put('/:id',      authMiddleware, requireRole('perusahaan'), c.update);
router.delete('/:id',   authMiddleware, requireRole('perusahaan','admin'), c.remove);
router.put('/:id/status', authMiddleware, requireRole('admin'), c.updateStatus);

module.exports = router;

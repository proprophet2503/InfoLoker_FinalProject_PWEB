const router  = require('express').Router();
const multer  = require('multer');
const { authMiddleware, requireRole } = require('../middleware/authMiddleware');
const { cvUpload, fotoUpload } = require('../middleware/uploadMiddleware');
const c = require('../controllers/lamaranController');

const upload = multer({ storage: multer.memoryStorage() });
const fields = [{ name: 'cv', maxCount: 1 }, { name: 'foto', maxCount: 1 }];

router.post('/',          authMiddleware, requireRole('pelamar'), cvUpload.fields(fields), c.submit);
router.get('/saya',       authMiddleware, requireRole('pelamar'), c.milikSaya);
router.put('/:id/status', authMiddleware, requireRole('perusahaan','admin'), c.updateStatus);
router.get('/lowongan/:lowonganId', authMiddleware, requireRole('perusahaan','admin'), c.listByLowongan);

module.exports = router;

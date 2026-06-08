const router = require('express').Router();
const { authMiddleware, requireRole } = require('../middleware/authMiddleware');
const { fotoUpload, logoUpload } = require('../middleware/uploadMiddleware');
const c = require('../controllers/profilController');

router.get('/saya',        authMiddleware, c.getSaya);
router.put('/saya',        authMiddleware, c.updateSaya);
router.post('/foto',       authMiddleware, requireRole('pelamar'),    fotoUpload.single('foto'), c.uploadFoto);
router.post('/logo',       authMiddleware, requireRole('perusahaan'), logoUpload.single('logo'), c.uploadLogo);

module.exports = router;

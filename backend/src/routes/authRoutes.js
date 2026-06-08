const router = require('express').Router();
const { body } = require('express-validator');
const { register, login } = require('../controllers/authController');

const validateRegister = [
  body('nama').trim().isLength({ min: 2 }).withMessage('Nama minimal 2 karakter'),
  body('email').isEmail().normalizeEmail().withMessage('Email tidak valid'),
  body('password').isLength({ min: 8 }).matches(/\d/).withMessage('Password min 8 karakter dan mengandung angka'),
  body('role').isIn(['pelamar','perusahaan']).withMessage('Role tidak valid'),
];

router.post('/register', validateRegister, register);
router.post('/login', [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
], login);

module.exports = router;

const multer = require('multer');
const path   = require('path');
const { v4: uuidv4 } = require('uuid');

function makeStorage(dest) {
  return multer.diskStorage({
    destination: path.join(__dirname, '../../uploads', dest),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase();
      cb(null, uuidv4() + ext);
    },
  });
}

const cvUpload   = multer({ storage: makeStorage('cv'),   limits: { fileSize: parseInt(process.env.MAX_FILE_SIZE_CV   || '5242880') }, fileFilter: pdfOnly   });
const fotoUpload = multer({ storage: makeStorage('foto'), limits: { fileSize: parseInt(process.env.MAX_FILE_SIZE_FOTO || '2097152') }, fileFilter: imageOnly });
const logoUpload = multer({ storage: makeStorage('logo'), limits: { fileSize: parseInt(process.env.MAX_FILE_SIZE_LOGO || '1048576') }, fileFilter: imageOnly });

function pdfOnly(_req, file, cb) {
  cb(null, file.mimetype === 'application/pdf');
}

function imageOnly(_req, file, cb) {
  cb(null, ['image/jpeg','image/png'].includes(file.mimetype));
}

module.exports = { cvUpload, fotoUpload, logoUpload };

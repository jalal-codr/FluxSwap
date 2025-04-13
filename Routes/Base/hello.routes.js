const express = require('express');
const router = express.Router();
const {sayHello} = require('../../controllers/base');

router.get('/',sayHello);

module.exports = router;

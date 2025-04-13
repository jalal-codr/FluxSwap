const  express = require('express');
const router = express.Router();
const helloRoute = require('./Base/hello.routes');

router.get('/',helloRoute);



module.exports = router;

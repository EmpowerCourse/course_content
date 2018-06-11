var express = require('express');
var router = express.Router();

/* GET home page. */
router.get('/', function(req, res, next) {
  res.render('index', { title: 'our first Express app!', message: null });
});

router.post('/index', function(req, res, next) {
  res.render('index', { title: '!message was received', message: req.body.message });
});

module.exports = router;

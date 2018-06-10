var express = require('express');
var router = express.Router();

// Require controller modules.
var beverage_controller = require('../controllers/beverageController');

router.get('/beverages', beverage_controller.index);
router.post('/beverages', beverage_controller.add);
router.get('/beverages/delete/:id', beverage_controller.delete);
module.exports = router;
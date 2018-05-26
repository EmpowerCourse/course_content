var mongoose = require('mongoose');
var Schema = mongoose.Schema;
var Beverage = new Schema({
    name          : String,
    description    : String
}, { collection: 'beverage' });
module.exports = mongoose.model('Beverage', Beverage);
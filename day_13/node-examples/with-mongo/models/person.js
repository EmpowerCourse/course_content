var mongoose = require('mongoose');
var Schema = mongoose.Schema;
var Person = new Schema({
    first_name   : String,
    last_name    : String,
    phone    : String
}, { collection: 'people' });
module.exports = mongoose.model('Person', Person);
var createError = require('http-errors');
var express = require('express');
var path = require('path');
var cookieParser = require('cookie-parser');
var bodyParser = require('body-parser');
var logger = require('morgan');

var mongoose = require('mongoose');
// var mongoDB = 'mongodb+srv://ews1-user:ews1-user1@empower18-ws1-pgyeb.mongodb.net/admin';
// var mongoDB = 'mongodb+srv://ews1-user:ews1-user1@empower18-ws1-pgyeb.mongodb.net/db1';
var mongoDB = 'mongodb://ews1-user:ews1-user1@empower18-ws1-shard-00-00-pgyeb.mongodb.net:27017,empower18-ws1-shard-00-01-pgyeb.mongodb.net:27017,empower18-ws1-shard-00-02-pgyeb.mongodb.net:27017/db1?ssl=true&replicaSet=empower18-ws1-shard-0&authSource=admin&retryWrites=true';
dbOptions = {
    keepAlive: 1000,
    connectTimeoutMS: 30000,
    native_parser: true,
    auto_reconnect: false,
    poolSize: 10
  };
mongoose.connect(mongoDB, dbOptions);
mongoose.Promise = global.Promise;
const db = mongoose.connection;
db.on('error', (err) => {
	console.log(err);
});
db.once('open', (err) => {
	if (err) {
		console.log(err);
	} 
	// else {
	// 	console.log("SUCCESSFUL DB CONNECTION", db);
	// }
});

var indexRouter = require('./routes/index');
var usersRouter = require('./routes/users');
var catalog = require('./routes/catalog');

var app = express();

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

app.use(logger('dev'));
// app.use(express.json());
// app.use(express.urlencoded({ extended: false }));
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));

app.use('/', indexRouter);
app.use('/users', usersRouter);
app.use('/catalog', catalog);

// catch 404 and forward to error handler
app.use(function(req, res, next) {
  next(createError(404));
});

// error handler
app.use(function(err, req, res, next) {
  // set locals, only providing error in development
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  // render the error page
  res.status(err.status || 500);
  res.render('error');
});

module.exports = app;

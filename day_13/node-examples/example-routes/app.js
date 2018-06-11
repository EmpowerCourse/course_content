var express = require('express'),
  app = express(),
  http = require('http'),
  path = require('path'),
  bodyParser = require('body-parser'),
  relativeAssetsPath = 'assets'
  ;

// configure
var port = process.env.PORT || 8077;
// parse application/x-www-form-urlencoded 
app.use(bodyParser.urlencoded({ extended: false }))
// parse application/json 
app.use(bodyParser.json())

app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'jade');

// all static paths
app.use(express.static(path.join(__dirname, 'static')));

// define a few routes

// send some composed text
function homeRoute(req, res) {
  res.end('index page called!');
}
app.get('/', homeRoute);

// parse a querystring parameter
app.get('/home', function (req, res) {
  if (req.query.param1) {
    res.end('home page called with querystring parameter ['+ req.query.param1 +']!');
  } else {
    res.end('home page called with no querystring parameter!');
  }
});

// parse a url parameter
app.get('/home/:param1', function (req, res) {
  if (req.params.param1) {
    res.end('home page called with url parameter ['+ req.params.param1 +']!');
  } else {
    res.end('home page called with no url parameter!');
  }
});

// send a raw file as a result
app.get('/p1', function(req, res) {
  var absoluteFilePath = path.join(__dirname, relativeAssetsPath, 'bang.jpg');
  res.sendFile(absoluteFilePath);
});

// render a view, passing a viewmodel
app.get('/p2', function(req, res) {
  var viewModel = {
    variablePassedFromActionToTheView: 'Hi There!'
  };
  res.render('p2', viewModel);
});

// posted content
app.post('/p3', function(req, res) {
  var viewModel = {
    fullName: req.body.firstName + " " + req.body.lastName
  };
  res.render('p3', viewModel);
});

// start listening
app.listen(port, function () {
  console.log('express server started on port %s', port);
});

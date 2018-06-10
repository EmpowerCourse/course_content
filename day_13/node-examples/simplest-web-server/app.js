var http = require('http'),
	port = 1335;

http.createServer(function(req, res) {
	console.log(req.url + ' was requested with verb ' + req.method);
	res.end('requested path [' + req.url + ']');
}).listen(port, '127.0.0.1');

console.log('Started server on local port ' + port + '!');
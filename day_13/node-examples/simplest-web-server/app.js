var http = require('http');

http.createServer(function(request, response) {
	console.log(request.url + ' was requested with verb ' + request.method);
	response.end('You just now requested path [' + request.url + ']');
}).listen(8888);

console.log('We just launched a node web server on local port 8888!');
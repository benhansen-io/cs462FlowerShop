express = require('express')
fs = require('fs')
https = require('https');
http = require('http');

privateKey = fs.readFileSync('certs/private-key.pem').toString();
certificate = fs.readFileSync('certs/cert.pem').toString();

app = module.exports = express();

port = 8002
securePort = 8003

app = express();
http.createServer(app).listen(port);
https.createServer({key: privateKey, cert: certificate}, app).listen(securePort);

app.get "/", (req, res) ->
  res.send 'Ben Hansen'


console.log 'Listening on ports: ' + port + ', and ' + securePort

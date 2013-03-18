express = require('express')
fs = require('fs')
https = require('https')
http = require('http')
twilio = require('./server/modules/twilio-wrapper')

privateKey = fs.readFileSync('certs/private-key.pem').toString();
certificate = fs.readFileSync('certs/cert.pem').toString();

app = module.exports = express();

app.configure ->
  app.set('views', __dirname + '/server/views')
  app.set('view engine', 'jade')
  app.locals.pretty = true
  #	app.use(express.favicon())
  #	app.use(express.logger('dev'))
  app.use(express.bodyParser())
  app.use(express.cookieParser())
  app.use(express.session({ secret: 'super-duper-secret-secret' }))
  app.use(express.methodOverride())
  app.use(require('stylus').middleware({ src: __dirname + '/public/' }))
  app.use(express.static(__dirname + '/public'));

app.configure 'development',  ->
  app.use(express.errorHandler())

require(__dirname + '/server/router')(app);

port = 8002
securePort = 8003

http.createServer(app).listen(port);
https.createServer({key: privateKey, cert: certificate}, app).listen(securePort)

console.log('Listening on ports: ' + port + ', and ' + securePort)

twilio.makeCall()

express = require('express')

app = express()

app.get "/", (req, res) ->
  res.send 'Ben Hansen'

port = 80
app.listen(port)
console.log 'Listening on port: ' + port

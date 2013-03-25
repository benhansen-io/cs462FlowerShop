MongoDB = require("mongodb").Db
Server = require("mongodb").Server
moment = require("moment")
dbPort = 27017
dbHost = "localhost"
dbName = "node-login"

# establish the database connection
db = new MongoDB(dbName, new Server(dbHost, dbPort,
  auto_reconnect: true
),
  w: 1
)

db.open (e, d) ->
  if e
    console.log e
  else
    console.log "connected to database :: " + dbName

deliveries = db.collection("deliveries")

exports.addDelivery = (id, callback) ->
  callback()

exports.setBidAwardedTime = (id, callback) ->
  callback()

exports.setPickedUpTime = (id, callback) ->
  callback()

exports.setDeliveryCompleteTime = (id, callback) ->
  callback()

exports.getRankChange = (id, callback) ->
  callback(null, 1)

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

exports.addDelivery = (id) ->

exports.setBidAwardedTime = (id) ->

exports.setPickedUpTime = (id) ->

exports.setDeliveryCompleteTime = (id) ->

exports.getRankChange = (id) ->
  return 1

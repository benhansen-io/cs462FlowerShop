MongoDB = require("mongodb").Db
Server = require("mongodb").Server
moment = require("moment")
dbPort = 27017
dbHost = "localhost"
dbName = "node-login"

uniqueid = require('./uniqueid')

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

stores = db.collection("stores")

exports.addStore = (driverUser, name, latLong, callback) ->
  callbackESLID = uniqueid.generateUniqueId()
  newData =
    driverUser: driverUser
    name: name
    latLong: latLong
    callbackESLID: callbackESLID
  stores.insert(newData, {safe: true}, callback);

exports.getStoresForDriver = (driverUser, callback) ->
  stores.find({driverUser: driverUser}).toArray (e, res) ->
    if e?
      callback(e)
    else
      callback(null, res)

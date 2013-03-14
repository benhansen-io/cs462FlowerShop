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

bids = db.collection("bids")

exports.addBid = (deliveryID, driverName, deliveryTime, callback) ->
  newData =
    deliveryID: deliveryID
    driverName: driverName
    deliveryTime: deliveryTime
  bids.insert(newData, {safe: true}, callback);

exports.getDeliveryIDs = (callback) ->
  bids.distinct 'deliveryID', (e, res) ->
    if (e) callback(e)
    else callback(null, res)

exports.getBidsByDeliveryID = (deliveryID, callback) ->
  bids.find({deliveryID: deliveryID}).toArray (e, res) ->
    if (e) callback(e)
    else callback(null, res)

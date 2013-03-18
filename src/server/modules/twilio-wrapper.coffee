sys = require('sys')
settings = require('./settings')

ACCOUNT_SID = "AC14a7fa16c208bbbf43a0fea0752d9c9d"
AUTH_TOKEN = "1d2fc468c57f2bf85bef10614bfa5db5"
MY_HOSTNAME = settings.siteUrl

client = require('twilio')(ACCOUNT_SID, AUTH_TOKEN)
console.log "client: " + client

exports.sendSMS = (number, message) ->
  client.sendSms
    to: number # Any number Twilio can deliver to
    from: "+18013088762" # A number you bought from Twilio and can use for outbound communication
    body: "message" # body of the SMS message
  , (err, responseData) ->
    #this function is executed when a response is received from Twilio
    unless err # "err" is an error received during the request, if any

      # "responseData" is a JavaScript object containing data received from Twilio.
      # A sample response from sending an SMS message is here (click "JSON" to see how the data appears in JavaScript):
      # http://www.twilio.com/docs/api/rest/sending-sms#example-1
      console.log responseData.from # outputs "+14506667788"
      console.log responseData.body # outputs "word to your mother."
    else
      console.log "Error in sending SMS: " + err

messagedReceivedHandler = (req, res) ->
  console.log "Default handler has not been replaced"

exports.routes = (app) ->
  app.post "/sms_received", (req, res) ->
    console.log "SMS Received: " + JSON.stringify(req.body)
    messagedReceivedHandler req, res
    res.send "OK", 200

exports.setMessagedReceivedHandler = (handler) ->
  messagedReceivedHandler = handler


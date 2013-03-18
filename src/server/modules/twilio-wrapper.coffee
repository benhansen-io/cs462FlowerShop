sys = require('sys')
settings = require('./settings')

ACCOUNT_SID = "AC14a7fa16c208bbbf43a0fea0752d9c9d"
AUTH_TOKEN = "1d2fc468c57f2bf85bef10614bfa5db5"
MY_HOSTNAME = settings.siteUrl

client = require('twilio')(ACCOUNT_SID, AUTH_TOKEN)
console.log "client: " + client

exports.sendSMS = (number, callback) ->
  client.sendSms
    to: number # Any number Twilio can deliver to
    from: "+18013088762" # A number you bought from Twilio and can use for outbound communication
    body: "Testing twilio" # body of the SMS message
  , callback

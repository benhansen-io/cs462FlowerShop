sys = require('sys')
settings = require('settings')

TwilioClient = require('twilio').Client
ACCOUNT_SID = "AC14a7fa16c208bbbf43a0fea0752d9c9d"
AUTH_TOKEN = "1d2fc468c57f2bf85bef10614bfa5db5"
MY_HOSTNAME = settings.siteUrl

client = new TwilioClient(ACCOUNT_SID, AUTH_TOKEN, MY_HOSTNAME)

exports.makeCall = () ->

  phone = client.getPhoneNumber('+18013088762')

  phone.setup () ->
    phone.makeCall '+8012017088', null, (call) ->
      call.on 'answered', (callParams, response) ->
        response.append(new Twiml.Say('Howdy mom and or dad! I hope you are well! I know you know your son loves you!'));
        response.send();

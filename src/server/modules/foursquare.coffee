OAuth2 = require("oauth").OAuth2
AM = require("./account-manager")
https = require('https')

oa = new OAuth2(
  "YUQA4UNMFVOUJ4CLPQ3BYRZMYUI5IUDYDUZG3EMWOZT1NLGG",
    "YBCYO5LXII2UWWX0JQ35A1DJCAWG4V30UMWXNF2YIWWHU4UZ",
    "https://foursquare.com/",
    "/oauth2/authenticate"
    "/oauth2/access_token")

module.exports.routes = (app) ->
  if app?
    # Request an OAuth Request Token, and redirects the user to authorize it
    app.get "/foursquare_rd", (req, res) ->
      unless req.session.user?
        # if user is not logged-in redirect back to login page
        res.redirect "/"
      else
        additional_params =
          grant_type: "authorization_code",
          "redirect_uri": "https://ec2-107-20-72-23.compute-1.amazonaws.com/foursquare_rd"

        oa.getOAuthAccessToken req.param("code"), additional_params, (error, access_token, refresh_token, results) ->
          if error
            console.log "error"
            console.log error
            console.log "error: " + error
          else
            # store the tokens in the session
            console.log "access_token: " + access_token + "; refresh_token: " + refresh_token + "; results: " + results
            req.session.oa = oa
            req.session.access_token = access_token
            req.session.refresh_token = refresh_token
            AM.addToAccount req.session.user.user, {foursquare_access_token: access_token}, (error, doc) ->
              if error?
                console.log "error in updating account: " + error
            req.session.user.foursquare_access_token = access_token
            res.redirect "/home"

additional_params =
  "redirect_uri": "https://ec2-107-20-72-23.compute-1.amazonaws.com/foursquare_rd"
  "response_type": "code"
module.exports.authorizeUrl = oa.getAuthorizeUrl additional_params

getUserId = (user, callback) ->
  options =
    host: 'api.foursquare.com',
    path: '/v2/users/self?oauth_token=' + user.foursquare_access_token

  https.get(options, (res) ->
    console.log "RESPONSE: " + res
    result = JSON.parse(res)
    console.log "GET SUCCESSFUL: " + result
    user_id = result['response']['user']['id']
    callback null, user_id
  ).on('error', (e) ->
    console.log 'ERROR: ' + e.message
    callback e
  )


module.exports.getCheckins = (user, number, callback) ->
  getUserId user, (error, userId) ->
    if error?
      callback error
    else
      console.log "UserID: " + userId
      callback null, userId


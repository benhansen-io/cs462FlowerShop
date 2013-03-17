OAuth2 = require("oauth").OAuth2
AM = require("./account-manager")
https = require('https')

site_url = "https://ec2-50-16-175-129.compute-1.amazonaws.com"

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
          "redirect_uri": site_url + "/foursquare_rd"

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
            if req.session.user?
              req.session.user.foursquare_access_token = access_token
            else
              console.log "Trying to add access_token to non-existent user"
            res.redirect "/"

additional_params =
  "redirect_uri": site_url + "/foursquare_rd"
  "response_type": "code"
module.exports.authorizeUrl = oa.getAuthorizeUrl additional_params

getJSON = (options, callback) ->
  https.get(options, (res) ->
    output = ''

    res.on 'data', (chunk) ->
      output += chunk;

    res.on 'end', () ->
      result = JSON.parse(output)
      callback null, result

  ).on('error', (e) ->
    console.log 'ERROR: ' + e.message
    callback e
  )


getUserId = (foursquare_access_token, callback) ->
  options =
    host: 'api.foursquare.com',
    path: '/v2/users/self?oauth_token=' + foursquare_access_token

  getJSON options, (error, result) ->
    if error?
      callback error
    else
      user_id = result['response']['user']['id']
      callback null, user_id


module.exports.getCheckins = (foursquare_access_token, number, callback) ->
  options =
    host: 'api.foursquare.com',
    path: '/v2/users/self/checkins?oauth_token=' + foursquare_access_token + '&limit=' + number

  getJSON options, (error, result) ->
    if error?
      callback error
    else
      checkins = result['response']['checkins']['items']
      callback null, checkins

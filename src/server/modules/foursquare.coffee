OAuth2 = require("oauth").OAuth2

module.exports = (app) ->
  oa = new OAuth2(
    "YUQA4UNMFVOUJ4CLPQ3BYRZMYUI5IUDYDUZG3EMWOZT1NLGG",
      "YBCYO5LXII2UWWX0JQ35A1DJCAWG4V30UMWXNF2YIWWHU4UZ",
      "https://foursquare.com/",
      "/oauth2/authenticate"
      "/oauth2/access_token")

  if app?
    # Request an OAuth Request Token, and redirects the user to authorize it
    app.get "/foursquare_rd", (req, res) ->
      unless req.session.user?
        # if user is not logged-in redirect back to login page
        res.redirect "/"
      else
        oa.getOAuthAccessToken req.param("code"), {}, (error, access_token, refresh_token, results) ->
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
            res.redirect "/home"
  else
    additional_params =
      "redirect_uri": "https://ec2-107-20-72-23.compute-1.amazonaws.com/foursquare_rd"
      "response_type": "code"
    return oa.getAuthorizeUrl additional_params

CT = require("./modules/country-list")
AM = require("./modules/account-manager")
EM = require("./modules/email-dispatcher")
FS = require("./modules/foursquare")
module.exports = (app) ->

  # main login page
  app.get "/", (req, res) ->
    AM.getAllActiveRecords (e, records) ->
      if e?
        res.send "Error looking up records", 500
      else if ensureHasSetupFoursquare req, res
        console.log records
        res.render "home",
          title: "FlowerShop"
          udata: req.session.user
          users: records

  # main login page
  app.get "/profile/:user", (req, res) ->
    user = req.params["user"]
    AM.findByUsername user, (e, profileuser) ->
      if e? or !profileuser?
        res.send "User not found", 400
      else
        FS.getCheckins profileuser.foursquare_access_token, 10, (e, records) ->
          if e?
            res.send "Error looking up checkins: " + e, 500
          else if ensureHasSetupFoursquare req, res
            console.log records
            res.render "profile",
              title: "FlowerShop"
              udata: req.session.user
              profileuser: profileuser
              users: records

  # main login page
  app.get "/login", (req, res) ->
    # if already logged in, return to default page
    if req.session.user?
      res.redirect "/"
      return

    renderLogin = () ->
      res.render "login",
        title: "Hello - Please Login To Your Account"

    # check if the user's credentials are saved in a cookie
    if req.cookies.user is `undefined` or req.cookies.pass is `undefined`
      renderLogin()
    else
      # attempt automatic login
      AM.autoLogin req.cookies.user, req.cookies.pass, (o) ->
        if o?
          req.session.user = o
          res.redirect "/home"
          udata: req.session.user
        else
          renderLogin()


  app.post "/login", (req, res) ->
    AM.manualLogin req.param("user"), req.param("pass"), (e, o) ->
      unless o
        res.send e, 400
      else
        req.session.user = o
        if req.param("remember-me") is "true"
          res.cookie "user", o.user,
            maxAge: 900000
          res.cookie "pass", o.pass,
            maxAge: 900000
        res.send o, 200

  # apps main page
  app.get "/link_foursquare", (req, res) ->
    res.render "link_foursquare",
      title: "Link Foursquare Account"
      foursquare_url: FS.authorizeUrl
      udata: req.session.user


  app.post "/login", (req, res) ->
    unless req.param("user") is `undefined`
      AM.updateAccount
        user: req.param("user")
        name: req.param("name")
        email: req.param("email")
        country: req.param("country")
        pass: req.param("pass")
      , (e, o) ->
        if e
          res.send "error-updating-account", 400
        else
          req.session.user = o
          # update the user's login cookies if they exists
          if req.cookies.user isnt `undefined` and req.cookies.pass isnt `undefined`
            res.cookie "user", o.user,
              maxAge: 900000

            res.cookie "pass", o.pass,
              maxAge: 900000

          res.send "ok", 200

    else if req.param("logout") is "true"
      res.clearCookie "user"
      res.clearCookie "pass"
      req.session.destroy (e) ->
        res.send "ok", 200

  # logged-in user homepage
  app.get "/account", (req, res) ->
    unless req.session.user?
      # if user is not logged-in redirect back to login page
      res.redirect "/"
    else
      res.render "account",
        title: "Account"
        countries: CT
        udata: req.session.user



  # creating new accounts
  app.get "/signup", (req, res) ->
    res.render "signup",
      title: "Signup"
      countries: CT


  app.post "/signup", (req, res) ->
    AM.addNewAccount
      name: req.param("name")
      email: req.param("email")
      user: req.param("user")
      pass: req.param("pass")
      country: req.param("country")
    , (e) ->
      if e
        res.send e, 400
      else
        res.send "ok", 200


  # password reset
  app.post "/lost-password", (req, res) ->
    # look up the user's account via their email
    AM.getAccountByEmail req.param("email"), (o) ->
      if o
        res.send "ok", 200
        EM.dispatchResetPasswordLink o, (e, m) ->
          # this callback takes a moment to return
          # should add an ajax loader to give user feedback
          if e
            #	res.send('ok', 200);
            res.send "email-server-error", 400
            for k of e
              console.log "error : ", k, e[k]
      else
        res.send "email-not-found", 400


  app.get "/reset-password", (req, res) ->
    email = req.query["e"]
    passH = req.query["p"]
    AM.validateResetLink email, passH, (e) ->
      unless e is "ok"
        res.redirect "/"
      else
        # save the user's email in a session instead of sending to the client
        req.session.reset =
          email: email
          passHash: passH

        res.render "reset",
          title: "Reset Password"



  app.post "/reset-password", (req, res) ->
    nPass = req.param("pass")

    # retrieve the user's email from the session to lookup their account and reset password
    email = req.session.reset.email

    # destory the session immediately after retrieving the stored email
    req.session.destroy()
    AM.updatePassword email, nPass, (o) ->
      if o
        res.send "ok", 200
      else
        res.send "unable to update password", 400

  # view & delete accounts
  app.get "/print", (req, res) ->
    AM.getAllRecords (e, accounts) ->
      res.render "print",
        title: "Account List"
        accts: accounts

  app.post "/delete", (req, res) ->
    AM.deleteAccount req.body.id, (e, obj) ->
      unless e
        res.clearCookie "user"
        res.clearCookie "pass"
        req.session.destroy (e) ->
          res.send "ok", 200

      else
        res.send "record not found", 400

  app.get "/reset", (req, res) ->
    AM.delAllRecords ->
      res.redirect "/print"

  FS.routes(app)

  app.get "*", (req, res) ->
    res.render "404",
      title: "Page Not Found"

ensureIsSetupUser = (req, res) ->
  unless req.session.user?
    # if user is not logged-in redirect back to login page
    res.redirect "/"
  else
    ensureHasSetupFoursquare req, res

ensureHasSetupFoursquare = (req, res) ->
  if req.session.user?
    if req.session.user.foursquare_access_token?
      return true
    else
      res.redirect "/link_foursquare"
  else
    true

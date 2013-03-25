crypto = require('crypto')
async = require('async')
CT = require("./modules/country-list")
AM = require("./modules/account-manager")
BM = require("./modules/bid-manager")
EM = require("./modules/email-dispatcher")
ED = require("./modules/external-event-dispatcher")
uniqueid = require("./modules/uniqueid")

site_url = "https://ec2-54-242-133-248.compute-1.amazonaws.com"

module.exports = (app) ->
  # main login page
  app.get "/", (req, res) ->
    if ensureIsSetupUser req, res
      if req.session.user.type is "Driver"
        res.redirect "/home-driver"
      else if req.session.user.type is "FlowerShopOwner"
        res.redirect "/home-shopowner"

  app.get "/home-driver", (req, res) ->
    if ensureIsSetupUser req, res
      if req.session.user.type != "Driver"
        res.send "Not authorized", 400
      if not req.session.user.callbackESLID?
        id = uniqueid.generateUniqueId()
        AM.addToAccount req.session.user.user,
          callbackESLID: id,
        , (e, o) ->
          if e
            res.send "error-updating type", 400
          else
            console.log "added callbackESLID:" + id
            req.session.user.callbackESLID = id
            res.render "home-driver",
              udata: req.session.user
      else
        res.render "home-driver",
          udata: req.session.user

  app.post "/home-driver", (req, res) ->
    if ensureIsSetupUser req, res
      if req.param("esl") is `undefined`
        res.send "missing data", 400
      else
        AM.addToAccount req.session.user.user,
          esl: req.param("esl"),
        , (e, o) ->
          if e
            res.send "error-updating type", 400
          else
            req.session.user.esl = req.param("esl")
            res.redirect "/home-driver"

  app.get "/home-shopowner", (req, res) ->
    if ensureIsSetupUser req, res
      BM.getDeliveryIDs (e, ids) ->
        if e?
          res.send e, 500
        else if not ids?
          res.send "Received unexpected null from getDeliveryIDs", 500
        else
          bidsObj = {}
          async.map ids, (id, c) ->
            BM.getBidsByDeliveryID id, (e, bids) ->
              if e?
                console.log "Failed to get bids for deliveryID: " + id
                res.send "Failed to get bids for deliveryID: " + id, 500
                c e
              else
                console.log "Adding bids to bidsObj: " + JSON.stringify(bids)
                bidsObj[id] = bids
                c null
          , (e, unused) ->
            if e?
              console.log "Error collecting bids: " + e
              res.send "Error collecting bids: " + e
            else
              console.log "bidsByDeliveryID: " + JSON.stringify(bidsObj)
              res.render "home-shopowner",
                udata: req.session.user
                bidsByDeliveryID: bidsObj

  app.post "/home-shopowner", (req, res) ->
    if ensureIsSetupUser req, res
      if req.param("location") is `undefined`
        res.send "missing data", 400
      else
        AM.addToAccount req.session.user.user,
          location: req.param("location")
          lat: req.param("lat")
          lng: req.param("lng"),
        , (e, o) ->
          if e
            res.send "error-updating type", 400
          else
            req.session.user.location = req.param("location")
            req.session.user.lat = req.param("lat")
            req.session.user.lng = req.param("lng")
            res.redirect "/home-shopowner"

  app.post "/delivery-request", (req, res) ->
    if ensureIsSetupUser req, res
      if req.param("pickup-time") is `undefined` or
      req.param("delivery-location") is `undefined` or
      not req.session.user.location?
        res.send "missing data, make sure you have set a shop location", 400
      else
        uniqueID = uniqueid.generateUniqueId()
        eventData =
          _domain: "rfq"
          _name: "delivery_ready"
          shopAddress: req.session.user.location
          shopLat: req.session.user.lat
          shopLng: req.session.user.lng
          pickupTime: req.param "pickup-time" or "now"
          deliveryAddress: req.param "delivery-location"
          deliveryTime: req.param "delivery-time" or ""
          id: uniqueID

        console.log "Sending delivery_ready event to drivers"
        AM.getDriversWithESL (error, driversarray) ->
          if error?
            res.send error, 500
          for driver in driversarray
            console.log "Sending to driver: " + driver.name
            eventData['esl'] = site_url + "/driverESL/" + driver.callbackESLID
            ED.sendEvent driver.esl, eventData
        res.redirect "/home-shopowner"

  app.post "/selectBid", (req, res) ->
    if ensureIsSetupUser req, res
      if req.param("deliveryID") is `undefined` or
        req.param("driverESL") is `undefined` or
        req.param("driverID") is `undefined`
        err = "Invalid params"
        console.log err
        res.send err, 500
      else
        eventObj =
          _domain: "rfq"
          _name: "bid_awarded"
          id: req.param("deliveryID")
          driverID: req.param("driverID")
        ED.sendEvent req.param("driverESL"), eventObj

  app.post "/driverESL/:id", (req, res) ->
    callbackESLID = req.params.id
    console.log "Received event on /driverESL/" + callbackESLID
    AM.getDriverWithCallbackESLID callbackESLID, (e, driver) ->
      if e?
        console.log e
        res.send e, 500
      else
        event = req.body
        if event._domain is "rfq" and event._name is "bid_available"
          BM.addBid event.id, event.driverID, driver.esl, event.driverName, event.deliveryTime, (e) ->
            if e?
              console.log e
              res.send e, 500
            else
              console.log "Bid recorded"
              res.send "Bid recorded", 200
        else if event._domain is "delivery" and event._name is "complete"
          # just record it in DB
          console.log "Delivery Complete with deliveryID: " + event.deliveryID
        else
          console.log "unknown event"
          res.send "unknown event", 400

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
          res.redirect "/"
          udata: req.session.user
        else
          renderLogin()


  app.post "/login", (req, res) ->
    unless req.param("user") is `undefined`
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
    else if req.param("logout") is "true"
      res.clearCookie "user"
      res.clearCookie "pass"
      req.session.destroy (e) ->
        res.send "ok", 200

  app.post "/account", (req, res) ->
    unless req.param("user") is `undefined`
      AM.updateAccount
        user: req.param("user")
        name: req.param("name")
        email: req.param("email")
        country: req.param("country")
        pass: req.param("pass")
        type: req.param("type")
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
      type: req.param("type")
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

  app.get "*", (req, res) ->
    res.render "404",
      title: "Page Not Found"

ensureIsSetupUser = (req, res) ->
  unless req.session.user?
    # if user is not logged-in redirect back to login page
    res.redirect "/login"
    return false
  else
    return true

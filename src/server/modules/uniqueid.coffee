crypto = require("crypto")
exports.generateUniqueId = () ->
  shasum = crypto.createHash('sha1')
  shasum.update(Math.random() + "bensrandomseedfornogoodreason" + Math.random())
  uniqueID = new String(shasum.digest('base64'))
  return uniqueID

express = require "express"
favicon = require "serve-favicon"
https = require "https"

# node_redis client
{db} = require "./db"
{GITHUB_TOKEN_SET, GITHUB_AUTH_HASH, RESTRICTED_KEYS} = require "./constants"
require "./ghev"
#global.gh = gh

app = express()


app.use favicon "#{__dirname}/public/favicon.ico"


# collect the rawBody
app.use (req, res, next) ->
  data = ''
  req.setEncoding 'utf8'
  req.on 'data', (chunk) ->
    data += chunk
  req.on 'end', () ->
    req.rawBody = data
    next()


app.get '/auth_callback', (req, res) ->
  cb = (gh_response) ->
    str = ''
    gh_response.on 'data', (chunk) ->
      str += chunk
    gh_response.on 'end', () ->
      if gh_response.statusCode is 200
        access_token = JSON.parse(str).access_token
        gh.emit 'receiveAccessToken', access_token, () ->
          res.status(200).write("OK")
          res.send()
      else
        res.status(gh_response.statusCode).write(str)
        return res.send()
  gh.emit "requestToken", req, res, cb


# block calls to restricted keys
app.use (req, res, next) ->
  key = req.param "key"
  if key in RESTRICTED_KEYS
    res.status(403).write("no.")
    return res.send()
  next()


# authenticate with github token
app.use (req, res, next) ->
  token = req.query["access_token"] or req.headers["access_token"]
  if not token?
    res.status(403).write("Invalid Access Token")
    return res.send()
  db.sismember GITHUB_TOKEN_SET, token, (err, ismemberres) ->
    # what would the err be?
    if err?
      res.status(500).write(err.toString())
      return res.send()
    if ismemberres is 1
      next()
      return
    # not in our set
    else
      res.status(403).write("Invalid")
      return res.send()


GET_COMMANDS = [
  # Keys
  "EXISTS", "DUMP", "PTTL",
  # Strings
  "GET",
  # Lists
  "LRANGE",
  # Hashes,
  "HGET", "HLEN", "HKEYS"
]
app.get '/:command/:key', (req, res) ->
  c = req.param "command"
  key = req.param "key"
  if key in RESTRICTED_KEYS
    res.status(403).write("no.")
    return res.send()
  if c.toUpperCase() not in GET_COMMANDS
    res.status(400).write("unsupported command")
    return res.send()

  retrn = (err, dbres) ->
    if not err
      # http://stackoverflow.com/a/3886106/177293
      # #wat?
      if parseInt(dbres) is dbres
        dbres = dbres + ""
      return res.send(dbres)
    else
      res.status(500)
      return res.send(err.toString())

  args = [key]
  if req.query.args?
    args.push.apply args, req.query.args.split ','
  args.push retrn
  db[c].apply db, args


POST_COMMANDS = [
  # Keys
  "DEL", "RESTORE", "EXPIRE", "PEXPIRE",
  # Strings
  "APPEND", "SET",
  # Lists
  "LPUSH",
  # Hashes
  "HSET",
]
app.post '/:command/:key', (req, res) ->
  c = req.param "command"
  key = req.param "key"
  v = req.rawBody

  if c.toUpperCase() not in POST_COMMANDS
    res.status(400).write("unsupported command")
    return res.send()

  retrn = (err, dbres) ->
    if not err
      return res.send("true")
    else
      res.status(500)
      return res.send(err.toString())

  args = [key]
  if req.query.args?
    args.push.apply args, req.query.args.split ','
  args.push.apply args, [v, retrn]
  db[c].apply db, args

module.exports.app = app

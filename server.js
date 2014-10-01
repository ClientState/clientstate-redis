// Generated by CoffeeScript 1.8.0
(function() {
  var GET_COMMANDS, POST_COMMANDS, app, db, express, favicon, redis, repl, server, start,
    __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

  express = require("express");

  redis = require("redis");

  repl = require("repl");

  favicon = require("serve-favicon");

  app = express();

  app.use(favicon("" + __dirname + "/public/favicon.ico"));

  app.use(function(req, res, next) {
    var data;
    data = '';
    req.setEncoding('utf8');
    req.on('data', function(chunk) {
      return data += chunk;
    });
    return req.on('end', function() {
      req.rawBody = data;
      return next();
    });
  });

  db = redis.createClient();

  start = function(context) {
    var k, r, v, _results;
    r = repl.start("> ");
    _results = [];
    for (k in context) {
      v = context[k];
      _results.push(r.context[k] = v);
    }
    return _results;
  };

  GET_COMMANDS = ["GET", "LRANGE"];

  app.get('/:command/:key', function(req, res) {
    var args, c, key, retrn, _ref;
    c = req.param("command");
    key = req.param("key");
    if (_ref = c.toUpperCase(), __indexOf.call(GET_COMMANDS, _ref) < 0) {
      res.status(400).write("unsupported command");
      return res.send();
    }
    retrn = function(err, dbres) {
      if (!err) {
        return res.send(dbres);
      } else {
        res.status(500);
        return res.send(err.toString());
      }
    };
    args = [key];
    if (req.query.args != null) {
      args.push.apply(args, req.query.args.split(','));
    }
    args.push(retrn);
    return db[c].apply(db, args);
  });

  POST_COMMANDS = ["APPEND", "SET", "LPUSH"];

  app.post('/:command/:key', function(req, res) {
    var c, key, retrn, v, _ref;
    c = req.param("command");
    key = req.param("key");
    v = req.rawBody;
    if (_ref = c.toUpperCase(), __indexOf.call(POST_COMMANDS, _ref) < 0) {
      res.status(400).write("unsupported command");
      return res.send();
    }
    retrn = function(err, dbres) {
      if (!err) {
        return res.send("true");
      } else {
        res.status(500);
        return res.send(err.toString());
      }
    };
    return db[c](key, v, retrn);

    /*
     * string or object is LPUSHed as a string
     * Array LPUSHs each member
    if v instanceof Array
      v = (JSON.stringify(m) for m in v)
       * create args for multiple values eg LPUSH
       * http://stackoverflow.com/a/18094767/177293
      v.unshift key
      v.push retrn
      db[c].apply db, v
    else
       * http://stackoverflow.com/q/203739/177293
      if v.constructor is String
        console.log "STRING", v
        db[c] key, v, retrn
      else
        console.log "NOT STRING", v
        db[c] key, JSON.stringify(v), retrn
     */
  });


  /*
  logErrors = (err, req, res, next) ->
    console.error err.stack
    next err
  
  app.use logErrors
   */

  server = app.listen(3000, function() {
    return console.log('Listening on port %d', server.address().port);
  });

}).call(this);

// Generated by CoffeeScript 1.8.0
(function() {
  var app, server;

  app = require("./app").app;

  server = app.listen(3000, function() {
    return console.log('Listening on port %d', server.address().port);
  });

}).call(this);

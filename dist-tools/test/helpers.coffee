fs = require('fs')

evalCode = (code, preamble) ->
  eval """
    (function() {
      var window = GLOBAL;
      #{preamble};
      return #{code};
    })();
  """

module.exports =
  HiveTaxi: require('../../')
  build: require('../browser-builder')
  collector: require('../service-collector')
  chai: require('chai')
  evalCode: evalCode

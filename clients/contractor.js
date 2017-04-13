require('../lib/node_loader');
var HiveTaxi = require('../lib/core');
var Service = require('../lib/service');
var apiLoader = require('../lib/api_loader');

apiLoader.services['contractor'] = {};
HiveTaxi.Contractor = Service.defineService('contractor', ['1.0']);
Object.defineProperty(apiLoader.services['contractor'], '1.0', {
  get: function get() {
    var model = require('../apis/contractor-1.0.min.json');
    return model;
  },
  enumerable: true,
  configurable: true
});

module.exports = HiveTaxi.Contractor;

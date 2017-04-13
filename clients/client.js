require('../lib/node_loader');
var HiveTaxi = require('../lib/core');
var Service = require('../lib/service');
var apiLoader = require('../lib/api_loader');

apiLoader.services['client'] = {};
HiveTaxi.Client = Service.defineService('client', ['1.0']);
Object.defineProperty(apiLoader.services['client'], '1.0', {
  get: function get() {
    var model = require('../apis/client-1.0.min.json');
    model.waiters = require('../apis/client-1.0.waiters2.json').waiters;
    return model;
  },
  enumerable: true,
  configurable: true
});

module.exports = HiveTaxi.Client;

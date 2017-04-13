require('../lib/node_loader');
var HiveTaxi = require('../lib/core');
var Service = require('../lib/service');
var apiLoader = require('../lib/api_loader');

apiLoader.services['cartographer'] = {};
HiveTaxi.Cartographer = Service.defineService('cartographer', ['1.0']);
Object.defineProperty(apiLoader.services['cartographer'], '1.0', {
  get: function get() {
    var model = require('../apis/cartographer-1.0.min.json');
    return model;
  },
  enumerable: true,
  configurable: true
});

module.exports = HiveTaxi.Cartographer;

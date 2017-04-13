var HiveTaxi = require('./core');

HiveTaxi.apiLoader = function(svc, version) {
  if (!HiveTaxi.apiLoader.services.hasOwnProperty(svc)) {
    throw new Error('InvalidService: Failed to load api for ' + svc);
  }
  return HiveTaxi.apiLoader.services[svc][version];
};

HiveTaxi.apiLoader.services = {};

module.exports = HiveTaxi.apiLoader;
require('./node_loader');

var HiveTaxi = require('./core');

// Load all service classes
require('../clients/all');
module.exports = HiveTaxi;

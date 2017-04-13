require('./browser_loader');

var HiveTaxi = require('./core');

if (typeof window !== 'undefined') window.HiveTaxi = HiveTaxi;
if (typeof module !== 'undefined') module.exports = HiveTaxi;
if (typeof self !== 'undefined') self.HiveTaxi = HiveTaxi;

/**
 * @private
 * DO NOT REMOVE
 * browser builder will strip out this line if services are supplied on the command line.
 */
require('../clients/browser_default');
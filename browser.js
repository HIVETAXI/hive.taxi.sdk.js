require('./lib/browser_loader');

var HiveTaxi = require('./lib/core');
if (typeof window !== 'undefined') window.HiveTaxi = HiveTaxi;
if (typeof module !== 'undefined') module.exports = HiveTaxi;
if (typeof self !== 'undefined') self.HiveTaxi = HiveTaxi;
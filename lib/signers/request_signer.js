var HiveTaxi = require('../core');
var inherit = HiveTaxi.util.inherit;

/**
 * @api private
 */
HiveTaxi.Signers.RequestSigner = inherit({
  constructor: function RequestSigner(request) {
    this.request = request;
  },

  setServiceClientId: function setServiceClientId(id) {
    this.serviceClientId = id;
  },

  getServiceClientId: function getServiceClientId() {
    return this.serviceClientId;
  }
});

HiveTaxi.Signers.RequestSigner.getVersion = function getVersion(version) {
  switch (version) {
    case 'v1': return HiveTaxi.Signers.V1;
    case 'basic_auth': return HiveTaxi.Signers.BasicAuth;
  }
  throw new Error('Unknown signing version ' + version);
};

require('./basic_auth');
require('./v1');
require('./presign');

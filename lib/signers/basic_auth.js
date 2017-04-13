var HiveTaxi = require('../core');
var inherit = HiveTaxi.util.inherit;

/**
 * @api private
 */
HiveTaxi.Signers.BasicAuth = inherit(HiveTaxi.Signers.RequestSigner, {
  constructor: function BasicAuth(request, serviceName, signatureCache) {
    HiveTaxi.Signers.RequestSigner.call(this, request);
    this.serviceName = serviceName;
    this.signatureCache = signatureCache;
  },

  algorithm: 'Basic',

  addAuthorization: function addAuthorization(credentials) {
    this.request.headers['Authorization'] = this.authorization(credentials);
    // TODO remove after proper CORS setup
    delete this.request.headers['User-Agent'];
    delete this.request.headers['X-Hive-User-Agent'];
    // END TODO
  },

  credentialString: function credentialString(credentials) {
    return HiveTaxi.util.base64.encode(credentials.accessKeyId + ':' + credentials.secretAccessKey);
  },

  authorization: function authorization(credentials) {
    var parts = [];
    var credString = this.credentialString(credentials);
    parts.push(this.algorithm + ' ' + credString);
    return parts.join(', ');
  }

});

module.exports = HiveTaxi.Signers.BasicAuth;

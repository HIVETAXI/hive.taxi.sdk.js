var HiveTaxi = require('../core');
var inherit = HiveTaxi.util.inherit;

/**
 * @api private
 */
var expiresHeader = 'presigned-expires';

/**
 * @api private
 */
function signedUrlBuilder(request) {
  var expires = request.httpRequest.headers[expiresHeader];
  var signerClass = request.service.getSignerClass(request);

  delete request.httpRequest.headers['User-Agent'];
  delete request.httpRequest.headers['X-Hive-User-Agent'];

  if (signerClass === HiveTaxi.Signers.V1) {
    if (expires > 604800) { // one week expiry is invalid
      var message = 'Presigning does not support expiry time greater ' +
                    'than a week with SigV1 signing.';
      throw HiveTaxi.util.error(new Error(), {
        code: 'InvalidExpiryTime', message: message, retryable: false
      });
    }
    request.httpRequest.headers[expiresHeader] = expires;
  } else if (signerClass === HiveTaxi.Signers.S3) {
    request.httpRequest.headers[expiresHeader] = parseInt(
      HiveTaxi.util.date.unixTimestamp() + expires, 10).toString();
  } else {
    throw HiveTaxi.util.error(new Error(), {
      message: 'Presigning only supports SigV1 signing.',
      code: 'UnsupportedSigner', retryable: false
    });
  }
}

/**
 * @api private
 */
function signedUrlSigner(request) {
  var endpoint = request.httpRequest.endpoint;
  var parsedUrl = HiveTaxi.util.urlParse(request.httpRequest.path);
  var queryParams = {};

  if (parsedUrl.search) {
    queryParams = HiveTaxi.util.queryStringParse(parsedUrl.search.substr(1));
  }

  HiveTaxi.util.each(request.httpRequest.headers, function (key, value) {
    if (key === expiresHeader) key = 'Expires';
    if (key.indexOf('x-hive-meta-') === 0) {
      // Delete existing, potentially not normalized key
      delete queryParams[key];
      key = key.toLowerCase();
    }
    queryParams[key] = value;
  });
  delete request.httpRequest.headers[expiresHeader];

  var auth = queryParams['Authorization'].split(' ');
  if (auth[0] === 'HIVE') {
    auth = auth[1].split(':');
    queryParams['AccessKeyId'] = auth[0];
    queryParams['Signature'] = auth[1];
  } else if (auth[0] === 'HIVE-HMAC-SHA256') { // SigV1 signing
    auth.shift();
    var rest = auth.join(' ');
    var signature = rest.match(/Signature=(.*?)(?:,|\s|\r?\n|$)/)[1];
    queryParams['X-Hive-Signature'] = signature;
    delete queryParams['Expires'];
  }
  delete queryParams['Authorization'];
  delete queryParams['Host'];

  // build URL
  endpoint.pathname = parsedUrl.pathname;
  endpoint.search = HiveTaxi.util.queryParamsToString(queryParams);
}

/**
 * @api private
 */
HiveTaxi.Signers.Presign = inherit({
  /**
   * @api private
   */
  sign: function sign(request, expireTime, callback) {
    request.httpRequest.headers[expiresHeader] = expireTime || 3600;
    request.on('build', signedUrlBuilder);
    request.on('sign', signedUrlSigner);
    request.removeListener('afterBuild',
      HiveTaxi.EventListeners.Core.SET_CONTENT_LENGTH);
    request.removeListener('afterBuild',
      HiveTaxi.EventListeners.Core.COMPUTE_SHA256);

    request.emit('beforePresign', [request]);

    if (callback) {
      request.build(function() {
        if (this.response.error) callback(this.response.error);
        else {
          callback(null, HiveTaxi.util.urlFormat(request.httpRequest.endpoint));
        }
      });
    } else {
      request.build();
      if (request.response.error) throw request.response.error;
      return HiveTaxi.util.urlFormat(request.httpRequest.endpoint);
    }
  }
});

module.exports = HiveTaxi.Signers.Presign;

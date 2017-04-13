var HiveTaxi = require('../core');
var inherit = HiveTaxi.util.inherit;

/**
 * @api private
 */
var cachedSecret = {};

/**
 * @api private
 */
var cacheQueue = [];

/**
 * @api private
 */
var maxCacheEntries = 50;

/**
 * @api private
 */
HiveTaxi.Signers.V1 = inherit(HiveTaxi.Signers.RequestSigner, {
  constructor: function V1(request, serviceName, signatureCache) {
    HiveTaxi.Signers.RequestSigner.call(this, request);
    this.serviceName = serviceName;
    this.signatureCache = signatureCache;
  },

  algorithm: 'hmac',

  addAuthorization: function addAuthorization(credentials, date, nonce) {
    var datetime = HiveTaxi.util.date.rfc822(date);

    this.nonce = nonce;
    this.addHeaders(credentials, datetime);

    this.request.headers['Authentication'] = this.authorization(credentials, datetime);
  },

  addHeaders: function addHeaders(credentials, datetime) {
    this.request.headers['X-Hive-Date'] = datetime;
    // TODO remove after proper CORS setup
    delete this.request.headers['X-Hive-Content-Sha256'];
    delete this.request.headers['User-Agent'];
    delete this.request.headers['X-Hive-User-Agent'];
    // END TODO
    if (credentials.sessionToken) {
      this.request.headers['x-hive-security-token'] = credentials.sessionToken;
    }
  },

  authorization: function authorization(credentials, datetime) {
    var parts = [];
    var nonce = this.nonce || (new Date).valueOf();
    var digest = this.signature(credentials, datetime, nonce);
    parts.push(this.algorithm + ' ' + credentials.accessKeyId + ':' + nonce + ':' + digest);
    return parts.join();
  },

  signature: function signature(credentials, datetime, nonce) {
    var cache = null;
    nonce = nonce || this.nonce;
    var cacheIdentifier = this.serviceName + (this.getServiceClientId() ? '_' + this.getServiceClientId() : '');
    if (this.signatureCache) {
      cache = cachedSecret[cacheIdentifier];
      // If there isn't already a cache entry, we'll be adding one
      if (!cache) {
        cacheQueue.push(cacheIdentifier);
        if (cacheQueue.length > maxCacheEntries) {
          // remove the oldest entry (may not be last one used)
          delete cachedSecret[cacheQueue.shift()];
        }
      }

    }
    var date = HiveTaxi.util.date.from(datetime).toDateString();

    if (!cache ||
        cache.akid !== credentials.accessKeyId ||
        cache.region !== this.request.region ||
        cache.date !== date) {

      var kSecret = this.secretAccessKey(credentials);

      if (!this.signatureCache) {
        return HiveTaxi.util.crypto.hmac(
          new HiveTaxi.util.Buffer(kSecret || '', 'binary'),
          this.stringToSign(datetime, nonce),
          'base64'
        );
      }

      cachedSecret[cacheIdentifier] = {
        region: this.request.region,
        date: date,
        key: kSecret,
        akid: credentials.accessKeyId
      };
    }

    var key = cachedSecret[cacheIdentifier].key;
    return HiveTaxi.util.crypto.hmac(
      new HiveTaxi.util.Buffer(key || '', 'binary'),
      this.stringToSign(datetime, nonce),
      'base64'
    );
  },

  secretAccessKey: function secretAccessKey(credentials) {
    if (credentials.secretAccessKey.match(/^\w+?:\/\//)) {
      var parts = credentials.secretAccessKey.split('://', 2),
          encoding = parts[0], secret = parts[1];
      switch (encoding.toLowerCase()) {
        case 'sha256':
          return secret; // as-is
        case 'b64':
        case 'base64':
          return HiveTaxi.util.base64.decode(secret);
        case 'text':
        case 'plain':
        case 'plain-text':
          return HiveTaxi.util.crypto.sha256(credentials.secretAccessKey);
        default:
          return ''; // Invalid encoding
      }
    } else {
      return HiveTaxi.util.crypto.sha256(credentials.secretAccessKey);
    }
  },

  stringToSign: function stringToSign(datetime, nonce) {
    var parts = [];
    parts.push(this.request.method);
    parts.push(this.request.pathname());
    parts.push(datetime);
    parts.push(nonce);
    return parts.join('');
  },

  canonicalString: function canonicalString() {
    var parts = [], pathname = this.request.pathname();
    pathname = HiveTaxi.util.uriEscapePath(pathname);

    parts.push(this.request.method);
    parts.push(pathname);
    parts.push(this.request.search());
    parts.push(this.canonicalHeaders() + '\n');
    parts.push(this.signedHeaders());
    // parts.push(this.hexEncodedBodyHash());
    return parts.join('\n');
  },

  canonicalHeaders: function canonicalHeaders() {
    var headers = [];
    HiveTaxi.util.each.call(this, this.request.headers, function (key, item) {
      headers.push([key, item]);
    });
    headers.sort(function (a, b) {
      return a[0].toLowerCase() < b[0].toLowerCase() ? -1 : 1;
    });
    var parts = [];
    HiveTaxi.util.arrayEach.call(this, headers, function (item) {
      var key = item[0].toLowerCase();
      if (this.isSignableHeader(key)) {
        parts.push(key + ':' +
          this.canonicalHeaderValues(item[1].toString()));
      }
    });
    return parts.join('\n');
  },

  canonicalHeaderValues: function canonicalHeaderValues(values) {
    return values.replace(/\s+/g, ' ').replace(/^\s+|\s+$/g, '');
  },

  signedHeaders: function signedHeaders() {
    var keys = [];
    HiveTaxi.util.each.call(this, this.request.headers, function (key) {
      key = key.toLowerCase();
      if (this.isSignableHeader(key)) keys.push(key);
    });
    return keys.sort().join(';');
  },

  // hexEncodedHash: function hash(string) {
  //   return HiveTaxi.util.crypto.sha256(string, 'hex');
  // },

  // hexEncodedBodyHash: function hexEncodedBodyHash() {
  //   if (this.request.headers['X-Hive-Content-Sha256']) {
  //     return this.request.headers['X-Hive-Content-Sha256'];
  //   } else {
  //     return this.hexEncodedHash(this.request.body || '');
  //   }
  // },

  unsignableHeaders: ['authentication', 'content-type', 'content-length', 'user-agent', 'expect'],

  isSignableHeader: function isSignableHeader(key) {
    if (key.toLowerCase().indexOf('x-hive-') === 0) return true;
    return this.unsignableHeaders.indexOf(key) < 0;
  }

});

module.exports = HiveTaxi.Signers.V1;

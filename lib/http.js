var HiveTaxi = require('./core');
var inherit = HiveTaxi.util.inherit;

/**
 * The endpoint that a service will talk to, for example,
 * `'https://hivetaxi.com/api'`. If
 * you need to override an endpoint for a service, you can
 * set the endpoint on a service by passing the endpoint
 * object with the `endpoint` option key:
 *
 * ```javascript
 * var ep = new HiveTaxi.Endpoint('apiproxy.example.com');
 * var cartographer = new HiveTaxi.Cartographer({endpoint: ep});
 * cartographer.service.endpoint.hostname == 'apiproxy.example.com'
 * ```
 *
 * Note that if you do not specify a protocol, the protocol will
 * be selected based on your current {HiveTaxi.config} configuration.
 *
 * @!attribute protocol
 *   @return [String] the protocol (http or https) of the endpoint
 *     URL
 * @!attribute hostname
 *   @return [String] the host portion of the endpoint, e.g.,
 *     example.com
 * @!attribute host
 *   @return [String] the host portion of the endpoint including
 *     the port, e.g., example.com:80
 * @!attribute port
 *   @return [Integer] the port of the endpoint
 * @!attribute href
 *   @return [String] the full URL of the endpoint
 */
HiveTaxi.Endpoint = inherit({

  /**
   * @overload Endpoint(endpoint)
   *   Constructs a new endpoint given an endpoint URL. If the
   *   URL omits a protocol (http or https), the default protocol
   *   set in the global {HiveTaxi.config} will be used.
   *   @param endpoint [String] the URL to construct an endpoint from
   */
  constructor: function Endpoint(endpoint, config) {
    HiveTaxi.util.hideProperties(this, ['slashes', 'auth', 'hash', 'search', 'query']);

    if (typeof endpoint === 'undefined' || endpoint === null) {
      throw new Error('Invalid endpoint: ' + endpoint);
    } else if (typeof endpoint !== 'string') {
      return HiveTaxi.util.copy(endpoint);
    }

    if (!endpoint.match(/^http/)) {
      var useSSL = config && config.sslEnabled !== undefined ?
        config.sslEnabled : HiveTaxi.config.sslEnabled;
      endpoint = (useSSL ? 'https' : 'http') + '://' + endpoint;
    }

    HiveTaxi.util.update(this, HiveTaxi.util.urlParse(endpoint));

    // Ensure the port property is set as an integer
    if (this.port) {
      this.port = parseInt(this.port, 10);
    } else {
      this.port = this.protocol === 'https:' ? 443 : 80;
    }
  }

});

/**
 * The low level HTTP request object, encapsulating all HTTP header
 * and body data sent by a service request.
 *
 * @!attribute method
 *   @return [String] the HTTP method of the request
 * @!attribute path
 *   @return [String] the path portion of the URI, e.g.,
 *     "/list/?start=5&num=10"
 * @!attribute headers
 *   @return [map<String,String>]
 *     a map of header keys and their respective values
 * @!attribute body
 *   @return [String] the request body payload
 * @!attribute endpoint
 *   @return [HiveTaxi.Endpoint] the endpoint for the request
 * @!attribute region
 *   @api private
 *   @return [String] the region, for signing purposes only.
 */
HiveTaxi.HttpRequest = inherit({

  /**
   * @api private
   */
  constructor: function HttpRequest(endpoint, region, customUserAgent, orgId) {
    endpoint = new HiveTaxi.Endpoint(endpoint);
    this.method = 'POST';
    this.path = endpoint.path || '/';
    this.headers = {};
    this.body = '';
    this.endpoint = endpoint;
    this.region = region;
    this.setUserAgent(customUserAgent);
    if (orgId) {
      this.setOrgIdHeader(orgId);
    }
  },

  /**
   * @api private
   */
  setUserAgent: function setUserAgent(customUserAgent) {
    var prefix = HiveTaxi.util.isBrowser() ? 'X-Hive-' : '';
    var customSuffix = '';
    if (typeof customUserAgent === 'string' && customUserAgent) {
      customSuffix += ' ' + customUserAgent;
    }
    this.headers[prefix + 'User-Agent'] = HiveTaxi.util.userAgent() + customSuffix;
  },

  setOrgIdHeader: function setOrgIdHeader(orgId) {
    this.headers['X-Hive-OrgId'] = orgId;
  },

  /**
   * @return [String] the part of the {path} excluding the
   *   query string
   */
  pathname: function pathname() {
    return this.path.split('?', 1)[0];
  },

  /**
   * @return [String] the query string portion of the {path}
   */
  search: function search() {
    var query = this.path.split('?', 2)[1];
    if (query) {
      query = HiveTaxi.util.queryStringParse(query);
      return HiveTaxi.util.queryParamsToString(query);
    }
    return '';
  }

});

/**
 * The low level HTTP response object, encapsulating all HTTP header
 * and body data returned from the request.
 *
 * @!attribute statusCode
 *   @return [Integer] the HTTP status code of the response (e.g., 200, 404)
 * @!attribute headers
 *   @return [map<String,String>]
 *      a map of response header keys and their respective values
 * @!attribute body
 *   @return [String] the response body payload
 * @!attribute [r] streaming
 *   @return [Boolean] whether this response is being streamed at a low-level.
 *     Defaults to `false` (buffered reads). Do not modify this manually, use
 *     {createUnbufferedStream} to convert the stream to unbuffered mode
 *     instead.
 */
HiveTaxi.HttpResponse = inherit({

  /**
   * @api private
   */
  constructor: function HttpResponse() {
    this.statusCode = undefined;
    this.headers = {};
    this.body = undefined;
    this.streaming = false;
    this.stream = null;
  },

  /**
   * Disables buffering on the HTTP response and returns the stream for reading.
   * @return [Stream, XMLHttpRequest, null] the underlying stream object.
   *   Use this object to directly read data off of the stream.
   * @note This object is only available after the {HiveTaxi.Request~httpHeaders}
   *   event has fired. This method must be called prior to
   *   {HiveTaxi.Request~httpData}.
   * @example Taking control of a stream
   *   request.on('httpHeaders', function(statusCode, headers) {
   *     if (statusCode < 300) {
   *       if (headers.etag === 'xyz') {
   *         // pipe the stream, disabling buffering
   *         var stream = this.response.httpResponse.createUnbufferedStream();
   *         stream.pipe(process.stdout);
   *       } else { // abort this request and set a better error message
   *         this.abort();
   *         this.response.error = new Error('Invalid ETag');
   *       }
   *     }
   *   }).send(console.log);
   */
  createUnbufferedStream: function createUnbufferedStream() {
    this.streaming = true;
    return this.stream;
  }
});


HiveTaxi.HttpClient = inherit({});

/**
 * @api private
 */
HiveTaxi.HttpClient.getInstance = function getInstance() {
  if (this.singleton === undefined) {
    this.singleton = new this();
  }
  return this.singleton;
};

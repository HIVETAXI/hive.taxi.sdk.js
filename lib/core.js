/**
 * The main HiveTaxi namespace
 */
var HiveTaxi = { util: require('./util') };

/**
 * @api private
 * @!macro [new] nobrowser
 *   @note This feature is not supported in the browser environment of the SDK.
 */
var _hidden = {}; _hidden.toString(); // hack to parse macro

module.exports = HiveTaxi;

HiveTaxi.util.update(HiveTaxi, {

  /**
   * @constant
   */
  VERSION: '1.0.0',

  /**
   * @api private
   */
  Signers: {},

  /**
   * @api private
   */
  Protocol: {
    Json: require('./protocol/json'),
    Query: require('./protocol/query'),
    Rest: require('./protocol/rest'),
    RestJson: require('./protocol/rest_json'),
    RestXml: require('./protocol/rest_xml'),
    JsonRpc: require('./protocol/json_rpc')
  },

  /**
   * @api private
   */
  XML: {
    Builder: require('./xml/builder'),
    Parser: null // conditionally set based on environment
  },

  /**
   * @api private
   */
  JSON: {
    Builder: require('./json/builder'),
    Parser: require('./json/parser')
  },

  /**
   * @api private
   */
  Model: {
    Api: require('./model/api'),
    Operation: require('./model/operation'),
    Shape: require('./model/shape'),
    Paginator: require('./model/paginator'),
    ResourceWaiter: require('./model/resource_waiter')
  },

  util: require('./util'),

  /**
   * @api private
   */
  apiLoader: function() { throw new Error('No API loader set'); }
});

require('./service');

require('./credentials');
require('./credentials/credential_provider_chain');

require('./config');
require('./http');
require('./sequential_executor');
require('./event_listeners');
require('./request');
require('./response');
require('./resource_waiter');
require('./signers/request_signer');
require('./param_validator');

/**
 * @readonly
 * @return [HiveTaxi.SequentialExecutor] a collection of global event listeners that
 *   are attached to every sent request.
 * @see HiveTaxi.Request HiveTaxi.Request for a list of events to listen for
 * @example Logging the time taken to send a request
 *   HiveTaxi.events.on('send', function startSend(resp) {
 *     resp.startTime = new Date().getTime();
 *   }).on('complete', function calculateTime(resp) {
 *     var time = (new Date().getTime() - resp.startTime) / 1000;
 *     console.log('Request took ' + time + ' seconds');
 *   });
 *
 *   new HiveTaxi.S3().listBuckets(); // prints 'Request took 0.285 seconds'
 */
HiveTaxi.events = new HiveTaxi.SequentialExecutor();

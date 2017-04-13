var util = require('./util');

// node.js specific modules
util.crypto.lib = require('crypto');
util.Buffer = require('buffer').Buffer;
util.domain = require('domain');
util.stream = require('stream');
util.url = require('url');
util.querystring = require('querystring');

var HiveTaxi = require('./core');

// Use default API loader function
require('./api_loader');

// Load the xml2js XML parser
HiveTaxi.XML.Parser = require('./xml/node_parser');

// Load Node HTTP client
require('./http/node');

// Load custom credential providers
require('./credentials/environment_credentials');
require('./credentials/file_system_credentials');
require('./credentials/shared_ini_file_credentials');

// Setup default chain providers
// If this changes, please update documentation for
// HiveTaxi.CredentialProviderChain.defaultProviders in
// credentials/credential_provider_chain.js
HiveTaxi.CredentialProviderChain.defaultProviders = [
  function () { return new HiveTaxi.EnvironmentCredentials('HIVE'); },
  function () { return new HiveTaxi.EnvironmentCredentials('HIVETAXI'); },
  function () { return new HiveTaxi.SharedIniFileCredentials(); }
];

// Update configuration keys
HiveTaxi.util.update(HiveTaxi.Config.prototype.keys, {
  credentials: function () {
    var credentials = null;
    new HiveTaxi.CredentialProviderChain([
      function () { return new HiveTaxi.EnvironmentCredentials('HIVE'); },
      function () { return new HiveTaxi.EnvironmentCredentials('HIVETAXI'); },
      function () { return new HiveTaxi.SharedIniFileCredentials(); }
    ]).resolve(function(err, creds) {
      if (!err) credentials = creds;
    });
    return credentials;
  },
  credentialProvider: function() {
    return new HiveTaxi.CredentialProviderChain();
  },
  region: function() {
    return process.env.HIVE_REGION || process.env.HIVETAXI_REGION;
  }
});

// Reset configuration
HiveTaxi.config = new HiveTaxi.Config();

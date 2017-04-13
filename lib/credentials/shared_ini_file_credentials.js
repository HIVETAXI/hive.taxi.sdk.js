var HiveTaxi = require('../core');
var path = require('path');

/**
 * Represents credentials loaded from shared credentials file
 * (defaulting to ~/.hivetaxi/credentials).
 *
 * ## Using the shared credentials file
 *
 * This provider is checked by default in the Node.js environment. To use the
 * credentials file provider, simply add your access and secret keys to the
 * ~/.hivetaxi/credentials file in the following format:
 *
 *     [default]
 *     hive_access_key_id = AKID...
 *     hive_secret_access_key = YOUR_SECRET_KEY
 *
 * ## Using custom profiles
 *
 * The SDK supports loading credentials for separate profiles. This can be done
 * in two ways:
 *
 * 1. Set the `HIVE_PROFILE` environment variable in your process prior to
 *    loading the SDK.
 * 2. Directly load the HiveTaxi.SharedIniFileCredentials provider:
 *
 * ```javascript
 * var creds = new HiveTaxi.SharedIniFileCredentials({profile: 'myprofile'});
 * HiveTaxi.config.credentials = creds;
 * ```
 *
 * @!macro nobrowser
 */
HiveTaxi.SharedIniFileCredentials = HiveTaxi.util.inherit(HiveTaxi.Credentials, {
  /**
   * Creates a new SharedIniFileCredentials object.
   *
   * @param options [map] a set of options
   * @option options profile [String] (HIVE_PROFILE env var or 'default')
   *   the name of the profile to load.
   * @option options filename [String] ('~/.hivetaxi/credentials') the filename
   *   to use when loading credentials.
   */
  constructor: function SharedIniFileCredentials(options) {
    HiveTaxi.Credentials.call(this);

    options = options || {};

    this.filename = options.filename;
    this.profile = options.profile || process.env.HIVE_PROFILE || 'default';
    this.get(function() {});
  },

  /**
   * Loads the credentials from the shared credentials file
   *
   * @callback callback function(err)
   *   Called after the shared INI file on disk is read and parsed. When this
   *   callback is called with no error, it means that the credentials
   *   information has been loaded into the object (as the `accessKeyId`,
   *   `secretAccessKey`, and `sessionToken` properties).
   *   @param err [Error] if an error occurred, this value will be filled
   * @see get
   */
  refresh: function refresh(callback) {
    if (!callback) callback = function(err) { if (err) throw err; };
    try {
      if (!this.filename) this.loadDefaultFilename();
      var creds = HiveTaxi.util.ini.parse(HiveTaxi.util.readFileSync(this.filename));
      var profile = creds[this.profile];

      if (typeof profile !== 'object') {
        throw HiveTaxi.util.error(
          new Error('Profile ' + this.profile + ' not found in ' + this.filename),
          { code: 'SharedIniFileCredentialsProviderFailure' }
        );
      }

      this.accessKeyId = profile['hive_access_key_id'];
      this.secretAccessKey = profile['hive_secret_access_key'];
      this.sessionToken = profile['hive_session_token'];

      if (!this.accessKeyId || !this.secretAccessKey) {
        throw HiveTaxi.util.error(
          new Error('Credentials not set in ' + this.filename +
                    ' using profile ' + this.profile),
          { code: 'SharedIniFileCredentialsProviderFailure' }
        );
      }
      this.expired = false;
      callback();
    } catch (err) {
      callback(err);
    }
  },

  /**
   * @api private
   */
  loadDefaultFilename: function loadDefaultFilename() {
    var env = process.env;
    var home = env.HOME ||
               env.USERPROFILE ||
               (env.HOMEPATH ? ((env.HOMEDRIVE || 'C:/') + env.HOMEPATH) : null);
    if (!home) {
      throw HiveTaxi.util.error(
        new Error('Cannot load credentials, HOME path not set'),
        { code: 'SharedIniFileCredentialsProviderFailure' }
      );
    }

    this.filename = path.join(home, '.hivetaxi', 'credentials');
  }
});

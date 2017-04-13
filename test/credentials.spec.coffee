helpers = require('./helpers')
HiveTaxi = helpers.HiveTaxi

validateCredentials = (creds, key, secret, session) ->
  expect(creds.accessKeyId).to.equal(key || 'akid')
  expect(creds.secretAccessKey).to.equal(secret || 'secret')
  expect(creds.sessionToken).to.equal(session || 'session')

describe 'HiveTaxi.Credentials', ->
  describe 'constructor', ->
    it 'should allow setting of credentials with keys', ->
      config = new HiveTaxi.Config(
        accessKeyId: 'akid'
        secretAccessKey: 'secret'
        sessionToken: 'session'
      )
      validateCredentials(config.credentials)

    it 'should allow setting of credentials as object', ->
      creds =
        accessKeyId: 'akid'
        secretAccessKey: 'secret'
        sessionToken: 'session'
      validateCredentials(new HiveTaxi.Credentials(creds))

    it 'defaults credentials to undefined when not passed', ->
      creds = new HiveTaxi.Credentials()
      expect(creds.accessKeyId).to.equal(undefined)
      expect(creds.secretAccessKey).to.equal(undefined)
      expect(creds.sessionToken).to.equal(undefined)

  describe 'needsRefresh', ->
    it 'needs refresh if credentials are not set', ->
      creds = new HiveTaxi.Credentials()
      expect(creds.needsRefresh()).to.equal(true)
      creds = new HiveTaxi.Credentials('akid')
      expect(creds.needsRefresh()).to.equal(true)

    it 'does not need refresh if credentials are set', ->
      creds = new HiveTaxi.Credentials('akid', 'secret')
      expect(creds.needsRefresh()).to.equal(false)

    it 'needs refresh if creds are expired', ->
      creds = new HiveTaxi.Credentials('akid', 'secret')
      creds.expired = true
      expect(creds.needsRefresh()).to.equal(true)

    it 'can be expired based on expireTime', ->
      creds = new HiveTaxi.Credentials('akid', 'secret')
      creds.expired = false
      creds.expireTime = new Date(0)
      expect(creds.needsRefresh()).to.equal(true)

    it 'needs refresh if expireTime is within expiryWindow secs from now', ->
      creds = new HiveTaxi.Credentials('akid', 'secret')
      creds.expired = false
      creds.expireTime = new Date(HiveTaxi.util.date.getDate().getTime() + 1000)
      expect(creds.needsRefresh()).to.equal(true)

    it 'does not need refresh if expireTime outside expiryWindow', ->
      creds = new HiveTaxi.Credentials('akid', 'secret')
      creds.expired = false
      ms = HiveTaxi.util.date.getDate().getTime() + (creds.expiryWindow + 5) * 1000
      creds.expireTime = new Date(ms)
      expect(creds.needsRefresh()).to.equal(false)

  describe 'get', ->
    it 'does not call refresh if not needsRefresh', ->
      spy = helpers.createSpy('done callback')
      creds = new HiveTaxi.Credentials('akid', 'secret')
      refresh = helpers.spyOn(creds, 'refresh')
      creds.get(spy)
      expect(refresh.calls.length).to.equal(0)
      expect(spy.calls.length).not.to.equal(0)
      expect(spy.calls[0].arguments[0]).not.to.exist
      expect(creds.expired).to.equal(false)

    it 'calls refresh only if needsRefresh', ->
      spy = helpers.createSpy('done callback')
      creds = new HiveTaxi.Credentials('akid', 'secret')
      creds.expired = true
      refresh = helpers.spyOn(creds, 'refresh').andCallThrough()
      creds.get(spy)
      expect(refresh.calls.length).not.to.equal(0)
      expect(spy.calls.length).not.to.equal(0)
      expect(spy.calls[0].arguments[0]).not.to.exist
      expect(creds.expired).to.equal(false)

if HiveTaxi.util.isNode()
  describe 'HiveTaxi.EnvironmentCredentials', ->
    beforeEach (done) ->
      process.env = {}
      done()

    afterEach ->
      process.env = {}

    describe 'constructor', ->
      it 'should be able to read credentials from env with a prefix', ->
        process.env.HiveTaxi_ACCESS_KEY_ID = 'akid'
        process.env.HiveTaxi_SECRET_ACCESS_KEY = 'secret'
        process.env.HiveTaxi_SESSION_TOKEN = 'session'
        creds = new HiveTaxi.EnvironmentCredentials('HiveTaxi')
        validateCredentials(creds)

      it 'should be able to read credentials from env without a prefix', ->
        process.env.ACCESS_KEY_ID = 'akid'
        process.env.SECRET_ACCESS_KEY = 'secret'
        process.env.SESSION_TOKEN = 'session'
        creds = new HiveTaxi.EnvironmentCredentials()
        validateCredentials(creds)

    describe 'refresh', ->
      it 'can refresh credentials', ->
        process.env.HiveTaxi_ACCESS_KEY_ID = 'akid'
        process.env.HiveTaxi_SECRET_ACCESS_KEY = 'secret'
        creds = new HiveTaxi.EnvironmentCredentials('HiveTaxi')
        expect(creds.accessKeyId).to.equal('akid')
        creds.accessKeyId = 'not_akid'
        expect(creds.accessKeyId).not.to.equal('akid')
        creds.refresh()
        expect(creds.accessKeyId).to.equal('akid')

  describe 'HiveTaxi.FileSystemCredentials', ->
    describe 'constructor', ->
      it 'should accept filename and load credentials from root doc', ->
        mock = '{"accessKeyId":"akid", "secretAccessKey":"secret","sessionToken":"session"}'
        helpers.spyOn(HiveTaxi.util, 'readFileSync').andReturn(mock)

        creds = new HiveTaxi.FileSystemCredentials('foo')
        validateCredentials(creds)

      it 'should accept filename and load credentials from credentials block', ->
        mock = '{"credentials":{"accessKeyId":"akid", "secretAccessKey":"secret","sessionToken":"session"}}'
        spy = helpers.spyOn(HiveTaxi.util, 'readFileSync').andReturn(mock)

        creds = new HiveTaxi.FileSystemCredentials('foo')
        validateCredentials(creds)

    describe 'refresh', ->
      it 'should refresh from given filename', ->
        mock = '{"credentials":{"accessKeyId":"RELOADED", "secretAccessKey":"RELOADED","sessionToken":"RELOADED"}}'
        helpers.spyOn(HiveTaxi.util, 'readFileSync').andReturn(mock)

        creds = new HiveTaxi.FileSystemCredentials('foo')
        validateCredentials(creds, 'RELOADED', 'RELOADED', 'RELOADED')

      it 'fails if credentials are not in the file', ->
        mock = '{"credentials":{}}'
        helpers.spyOn(HiveTaxi.util, 'readFileSync').andReturn(mock)

        new HiveTaxi.FileSystemCredentials('foo').refresh (err) ->
          expect(err.message).to.equal('Credentials not set in foo')

        expect(-> new HiveTaxi.FileSystemCredentials('foo').refresh()).
          to.throw('Credentials not set in foo')

  describe 'HiveTaxi.SharedIniFileCredentials', ->
    beforeEach ->
      delete process.env.HIVE_PROFILE
      delete process.env.HOME
      delete process.env.HOMEPATH
      delete process.env.HOMEDRIVE
      delete process.env.USERPROFILE

    describe 'constructor', ->
      it 'throws an error if HOME/HOMEPATH/USERPROFILE are not set', ->
        expect(-> new HiveTaxi.SharedIniFileCredentials().refresh()).
          to.throw('Cannot load credentials, HOME path not set')

      it 'uses HOMEDRIVE\\HOMEPATH if HOME and USERPROFILE are not set', ->
        process.env.HOMEDRIVE = 'd:/'
        process.env.HOMEPATH = 'homepath'
        creds = new HiveTaxi.SharedIniFileCredentials()
        creds.get();
        expect(creds.filename).to.equal('d:/homepath/.hivetaxi/credentials')

      it 'uses default HOMEDRIVE of C:/', ->
        process.env.HOMEPATH = 'homepath'
        creds = new HiveTaxi.SharedIniFileCredentials()
        creds.get();
        expect(creds.filename).to.equal('C:/homepath/.hivetaxi/credentials')

      it 'uses USERPROFILE if HOME is not set', ->
        process.env.USERPROFILE = '/userprofile'
        creds = new HiveTaxi.SharedIniFileCredentials()
        creds.get();
        expect(creds.filename).to.equal('/userprofile/.hivetaxi/credentials')

      it 'can override filename as a constructor argument', ->
        creds = new HiveTaxi.SharedIniFileCredentials(filename: '/etc/creds')
        creds.get();
        expect(creds.filename).to.equal('/etc/creds')

    describe 'loading', ->
      beforeEach -> process.env.HOME = '/home/user'

      it 'loads credentials from ~/.hivetaxi/credentials using default profile', ->
        mock = '''
        [default]
        hive_access_key_id = akid
        hive_secret_access_key = secret
        hive_session_token = session
        '''
        helpers.spyOn(HiveTaxi.util, 'readFileSync').andReturn(mock)

        creds = new HiveTaxi.SharedIniFileCredentials()
        creds.get();
        validateCredentials(creds)
        expect(HiveTaxi.util.readFileSync.calls[0].arguments[0]).to.equal('/home/user/.hivetaxi/credentials')

      it 'loads the default profile if HIVE_PROFILE is empty', ->
        process.env.HIVE_PROFILE = ''
        mock = '''
        [default]
        hive_access_key_id = akid
        hive_secret_access_key = secret
        hive_session_token = session
        '''
        helpers.spyOn(HiveTaxi.util, 'readFileSync').andReturn(mock)

        creds = new HiveTaxi.SharedIniFileCredentials()
        creds.get();
        validateCredentials(creds)

      it 'accepts a profile name parameter', ->
        mock = '''
        [foo]
        hive_access_key_id = akid
        hive_secret_access_key = secret
        hive_session_token = session
        '''
        spy = helpers.spyOn(HiveTaxi.util, 'readFileSync').andReturn(mock)

        creds = new HiveTaxi.SharedIniFileCredentials(profile: 'foo')
        creds.get();
        validateCredentials(creds)

      it 'sets profile based on ENV', ->
        process.env.HIVE_PROFILE = 'foo'
        mock = '''
        [foo]
        hive_access_key_id = akid
        hive_secret_access_key = secret
        hive_session_token = session
        '''
        spy = helpers.spyOn(HiveTaxi.util, 'readFileSync').andReturn(mock)

        creds = new HiveTaxi.SharedIniFileCredentials()
        creds.get();
        validateCredentials(creds)

    describe 'refresh', ->
      beforeEach -> process.env.HOME = '/home/user'

      it 'should refresh from disk', ->
        mock = '''
        [default]
        hive_access_key_id = RELOADED
        hive_secret_access_key = RELOADED
        hive_session_token = RELOADED
        '''
        helpers.spyOn(HiveTaxi.util, 'readFileSync').andReturn(mock)

        creds = new HiveTaxi.SharedIniFileCredentials()
        creds.get();
        validateCredentials(creds, 'RELOADED', 'RELOADED', 'RELOADED')

      it 'fails if credentials are not in the file', ->
        mock = ''
        helpers.spyOn(HiveTaxi.util, 'readFileSync').andReturn(mock)

        new HiveTaxi.SharedIniFileCredentials().refresh (err) ->
          expect(err.message).to.equal('Profile default not found in /home/user/.hivetaxi/credentials')

        expect(-> new HiveTaxi.SharedIniFileCredentials().refresh()).
          to.throw('Profile default not found in /home/user/.hivetaxi/credentials')

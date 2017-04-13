helpers = require('../helpers')
HiveTaxi = helpers.HiveTaxi
Operation = HiveTaxi.Model.Operation
svc = HiveTaxi.Protocol.RestJson

beforeEach ->
  helpers.spyOn(HiveTaxi.util, 'userAgent').andReturn('hivetaxi-sdk-js/0.1')

buildRequest = ->
  crt = new HiveTaxi.Contractor({region: 'region', endpoint: 'localhost', apiVersion: '1.0'})
  req = crt.makeRequest('getEmployees', {contractor: 100000044547, groupId: '100000051646'})
  req.build()
  req.httpRequest.headers['X-Hive-User-Agent'] = 'hivetaxi-sdk-js/0.1'
  req.httpRequest

buildSigner = (request, signatureCache) ->
  if typeof signatureCache != 'boolean'
    signatureCache = true
  return new HiveTaxi.Signers.V1(request || buildRequest(), 'Contractor', signatureCache)

buildSignerFromService = (signatureCache) ->
  if typeof signatureCache != 'boolean'
    signatureCache = true
  crt = new HiveTaxi.Contractor({region: 'region', endpoint: 'localhost', apiVersion: '1.0'})
  signer = buildSigner(null, signatureCache)
  signer.setServiceClientId(crt._clientId)
  return signer

MockJSONRESTService = helpers.util.inherit HiveTaxi.Service,
  endpointPrefix: 'mockservice'

operation = null
request = null
response = null
service = null

defop = (op) ->
  helpers.util.property(service.api.operations, 'sampleOperation',
    new Operation('sampleOperation', op, api: service.api))

build = -> svc.buildRequest(request); request

describe 'HiveTaxi.Signers.V1', ->
  date = new Date(1486033460000)
  nonce = '1048450919'
  secret = 'qwerty';
  datetime = HiveTaxi.util.date.rfc822(date)
  creds = null
  signature = 'N0RySpCZm7t72FjJJ6osHbUZrsASItIA2j3dO3/FBgE='
  authorization = 'hmac admin:' + nonce + ':' + signature
  signer = null

  beforeEach ->
    creds = accessKeyId: 'admin', secretAccessKey: secret, sessionToken: 'session'
    signer = buildSigner()
    signer.addAuthorization(creds, date, nonce)

  describe 'constructor', ->
    it 'can build a signer for a request object', ->
      req = buildRequest()
      signer = buildSigner(req)
      expect(signer.request).to.equal(req)
  describe 'addAuthorization', ->
    headers = {
      'Content-Type': 'application/json',
      'Content-Length': 85,
#      'X-Hive-Target': 'Employees.getEmployees',
      'Host': 'localhost',
      'X-Hive-Date': datetime,
      'x-hive-security-token' : 'session',
      'Authentication' : authorization
    }

    for key, value of headers
      func = (k) ->
        it 'should add ' + k + ' header', ->
          expect(signer.request.headers[k]).to.equal(headers[k])
      func(key)

  describe 'authorization', ->
    it 'should return authorization part for signer', ->
      expect(signer.authorization(creds, datetime)).to.equal(authorization)

  describe 'signature', ->
    it 'should generate proper signature', ->
      expect(signer.signature(creds, datetime)).to.equal(signature)

    it 'should generate proper signature for text:// secret', ->
      creds.secretAccessKey = 'text://qwerty'
      expect(signer.signature(creds, datetime)).to.equal(signature)

    it 'should generate proper signature for plain:// secret', ->
      creds.secretAccessKey = 'plain://qwerty'
      expect(signer.signature(creds, datetime)).to.equal(signature)

    it 'should generate proper signature for plain-text:// secret', ->
      creds.secretAccessKey = 'plain-text://qwerty'
      expect(signer.signature(creds, datetime)).to.equal(signature)

    it 'should generate proper signature for sha256-encoded secret', ->
      encoded_secret = HiveTaxi.util.crypto.sha256(secret)
      creds.secretAccessKey = 'sha256://' + encoded_secret
      expect(signer.signature(creds, datetime)).to.equal(signature);

    it 'should generate proper signature for base64-encoded secret', ->
      encoded_secret = HiveTaxi.util.crypto.sha256(secret)
      creds.secretAccessKey = 'base64://' + HiveTaxi.util.base64.encode(encoded_secret)
      expect(signer.signature(creds, datetime)).to.equal(signature);

    it 'should generate proper signature for b64-encoded (alias for base64) secret', ->
      encoded_secret = HiveTaxi.util.crypto.sha256(secret)
      creds.secretAccessKey = 'b64://' + HiveTaxi.util.base64.encode(encoded_secret)
      expect(signer.signature(creds, datetime)).to.equal(signature);

    it 'should not compute HMAC more than once', ->
      spy = helpers.spyOn(HiveTaxi.util.crypto, 'hmac').andCallThrough()
      signer.signature(creds, datetime)
      expect(spy.calls.length).to.eql(1)

    describe 'caching', ->
      hmacCallCount = null
      hmacCalls = null
      sha256CallCount = null
      sha256Calls = null

      beforeEach ->
        helpers.spyOn(HiveTaxi.util.crypto, 'hmac')
        helpers.spyOn(HiveTaxi.util.crypto, 'sha256')
        signer.signature(creds, datetime)
        hmacCalls = HiveTaxi.util.crypto.hmac.calls
        hmacCallCount = hmacCalls.length
        sha256Calls = HiveTaxi.util.crypto.sha256.calls
        sha256CallCount = sha256Calls.length

      it 'will cache a maximum of 50 clients', (done) ->
        maxCacheEntries = 50
        clientSigners = (buildSignerFromService() for i in [0..maxCacheEntries-1])
        hmacCallCount = hmacCalls.length
        sha256CallCount = sha256Calls.length
        #Get signature for all clients to store them in cache
        (clientSigners[i].signature(creds, datetime) for i in [0..clientSigners.length-1])
        expect(hmacCalls.length).to.equal(hmacCallCount + maxCacheEntries)
        expect(sha256Calls.length).to.equal(sha256CallCount + maxCacheEntries)
        #Signer should use cache
        hmacCallCount = hmacCalls.length
        sha256CallCount = sha256Calls.length
        clientSigners[0].signature(creds, datetime)
        expect(hmacCalls.length).to.equal(hmacCallCount + 1)
        expect(sha256Calls.length).to.equal(sha256CallCount)
        #add a new signer, pushing past cache limit
        newestSigner = buildSignerFromService()
        newestSigner.signature(creds, datetime)
        #old signer shouldn't be using cache anymore
        hmacCallCount = hmacCalls.length
        sha256CallCount = sha256Calls.length
        clientSigners[0].signature(creds, datetime)
        expect(hmacCalls.length).to.equal(hmacCallCount + 1)
        expect(sha256Calls.length).to.equal(sha256CallCount + 1)
        done()
        
      #Calling signer.signature should call hmac 1 time when caching, and 5 times when not caching
      it 'caches subsequent requests', ->
        signer.signature(creds, datetime)
        expect(hmacCalls.length).to.equal(hmacCallCount + 1)
        signer.signature(creds, datetime)
        expect(hmacCalls.length).to.equal(hmacCallCount + 2)

      it 'busts cache if caching is disabled', ->
        signer = buildSigner(null, false)
        sha256CallCount = sha256Calls.length
        signer.signature(creds, datetime)
        expect(sha256Calls.length).to.equal(sha256CallCount + 1)

      it 'busts cache if region changes', ->
        signer.request.region = 'new-region'
        signer.signature(creds, datetime)
        expect(sha256Calls.length).to.equal(sha256CallCount + 1)

      it 'busts cache if service changes', ->
        signer.serviceName = 'newService'
        signer.signature(creds, datetime)
        expect(sha256Calls.length).to.equal(sha256CallCount + 1)

      it 'busts cache if access key changes', ->
        creds.accessKeyId = 'NEWAKID'
        signer.signature(creds, datetime)
        expect(sha256Calls.length).to.equal(sha256CallCount + 1)

      it 'busts cache if date changes', ->
        newDate = new Date(date.getTime() + 1000000000)
        newDatetime = HiveTaxi.util.date.rfc822(newDate)
        signer.signature(creds, newDatetime)
        expect(sha256Calls.length).to.equal(sha256CallCount + 1)

      it 'uses a different cache if client is different', ->
        signer1 = buildSignerFromService()
        sha256CallCount = sha256Calls.length
        signer1.signature(creds, datetime)
        expect(sha256Calls.length).to.equal(sha256CallCount + 1)
        signer2 = buildSignerFromService()
        sha256CallCount = sha256Calls.length
        signer2.signature(creds, datetime)
        expect(sha256Calls.length).to.equal(sha256CallCount + 1)

      it 'works when using the same client', ->
        signer1 = buildSignerFromService()
        sha256CallCount = sha256Calls.length
        signer1.signature(creds, datetime)
        expect(sha256Calls.length).to.equal(sha256CallCount + 1)
        signer1.signature(creds, datetime)
        expect(sha256Calls.length).to.equal(sha256CallCount + 1)

  describe 'stringToSign', ->
    it 'should sign correctly generated input string', ->
      expect(signer.stringToSign(datetime, nonce)).to.equal 'POST/api/contractors/100000044547' + datetime + nonce

  describe 'canonicalString', ->
    beforeEach ->
      MockJSONRESTService.prototype.api = new HiveTaxi.Model.Api
        operations:
          sampleOperation:
            http:
              method: 'POST'
              uri: '/'
            input:
              type: 'structure'
              members: {}
            output:
              type: 'structure'
              members:
                a: type: 'string'
                b: type: 'string'
        shapes:
          structureshape:
            type: 'structure'
            members:
              a: type: 'string'
              b: type: 'string'

      HiveTaxi.Service.defineMethods(MockJSONRESTService)

      operation = MockJSONRESTService.prototype.api.operations.sampleOperation
      service = new MockJSONRESTService(region: 'region')
      request = new HiveTaxi.Request(service, 'sampleOperation')
      response = new HiveTaxi.Response(request)

    it 'sorts the search string', ->
      request.params = query: 'foo', cursor: 'initial', queryOptions: '{}'
      defop
        http: requestUri: '/path?format=sdk&pretty=true'
        input:
          type: 'structure'
          members:
            query:
              location: 'querystring'
              locationName: 'q'
            queryOptions:
              location: 'querystring'
              locationName: 'q.options'
            cursor:
              location: 'querystring'
              locationName: 'cursor'
      req = build()
      signer = new HiveTaxi.Signers.V1(req.httpRequest, 'mockservice')
      expect(signer.canonicalString().split('\n')[2]).to.equal('cursor=initial&format=sdk&pretty=true&q=foo&q.options=%7B%7D')

    it 'double URI encodes paths', ->
      request.params = ClientId: '111', AddressId: 'a:b:c'
      defop
        http: requestUri: '/client/{ClientId}/quick-address/{AddressId}/update'
        input:
          type: 'structure'
          members:
            ClientId:
              location: 'uri'
              locationName: 'ClientId'
            AddressId:
              location: 'uri'
              locationName: 'AddressId'
      req = build()
      signer = new HiveTaxi.Signers.V1(req.httpRequest, 'mockservice')
      expect(signer.canonicalString().split('\n')[1]).to.equal('/client/111/quick-address/a%253Ab%253Ac/update')

  describe 'canonicalHeaders', ->
    it 'should return headers', ->
      expect(signer.canonicalHeaders()).to.eql [
        'host:localhost',
#        'x-hive-content-sha256:c4f6509a8266e2e6bb3442091272baa28a8ac16de0821f3ffa2036c6cbd3bfba',
        'x-hive-date:' + datetime,
        'x-hive-security-token:session',
#        'x-hive-target:Employees.getEmployees',
#        'x-hive-user-agent:hivetaxi-sdk-js/0.1'
      ].join('\n')

    it 'should ignore Authentication header', ->
      signer.request.headers = {'Authentication': 'foo'}
      expect(signer.canonicalHeaders()).to.equal('')

    it 'should lowercase all header names (not values)', ->
      signer.request.headers = {'FOO': 'BAR'}
      expect(signer.canonicalHeaders()).to.equal('foo:BAR')

    it 'should sort headers by key', ->
      signer.request.headers = {abc: 'a', bca: 'b', Qux: 'c', bar: 'd'}
      expect(signer.canonicalHeaders()).to.equal('abc:a\nbar:d\nbca:b\nqux:c')

    it 'should compact multiple spaces in keys/values to a single space', ->
      signer.request.headers = {'Header': 'Value     with  Multiple   \t spaces'}
      expect(signer.canonicalHeaders()).to.equal('header:Value with Multiple spaces')

    it 'should strip starting and end of line spaces', ->
      signer.request.headers = {'Header': ' \t   Value  \t  '}
      expect(signer.canonicalHeaders()).to.equal('header:Value')

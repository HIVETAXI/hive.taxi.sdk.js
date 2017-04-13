helpers = require('./helpers')
HiveTaxi = helpers.HiveTaxi
MockService = helpers.MockService
metadata = require('../apis/metadata.json')

describe 'HiveTaxi.Service', ->

  config = null; service = null
  retryableError = (error, result) ->
    expect(service.retryableError(error)).to.eql(result)

  beforeEach (done) ->
    config = new HiveTaxi.Config()
    service = new HiveTaxi.Service(config)
    done()

  describe 'apiVersions', ->
    it 'should set apiVersions property', ->
      CustomService = HiveTaxi.Service.defineService('custom', ['1.2', '2.4'])
      expect(CustomService.apiVersions).to.eql(['1.2', '2.4'])

  describe 'constructor', ->
    it 'should use HiveTaxi.config copy if no config is provided', ->
      service = new HiveTaxi.Service()
      expect(service.config).not.to.equal(HiveTaxi.config)
      expect(service.config.sslEnabled).to.equal(true)

    it 'should merge custom options on top of global defaults if config provided', ->
      service = new HiveTaxi.Service(maxRetries: 5)
      expect(service.config.sslEnabled).to.equal(true)
      expect(service.config.maxRetries).to.equal(5)

    it 'merges service-specific configuration from global config', ->
      HiveTaxi.config.update(cartographer: endpoint: 'localhost')
      crt = new HiveTaxi.Cartographer
      expect(crt.endpoint.host).to.equal('localhost')
      delete HiveTaxi.config.cartographer

    it 'service-specific global config overrides global config', ->
      region = HiveTaxi.config.region
      HiveTaxi.config.update(region: 'ru-2', cartographer: region: 'ru-1')
      crt = new HiveTaxi.Cartographer
      expect(crt.config.region).to.equal('ru-1')
      HiveTaxi.config.region = region
      delete HiveTaxi.config.cartographer

    it 'service-specific local config overrides service-specific global config', ->
      HiveTaxi.config.update(cartographer: region: 'ru-2')
      crt = new HiveTaxi.Cartographer region: 'ru-1'
      expect(crt.config.region).to.equal('ru-1')
      delete HiveTaxi.config.cartographer

    it 'merges credential data into config', ->
      service = new HiveTaxi.Service(accessKeyId: 'foo', secretAccessKey: 'bar')
      expect(service.config.credentials.accessKeyId).to.equal('foo')
      expect(service.config.credentials.secretAccessKey).to.equal('bar')

    it 'should allow HiveTaxi.config to be object literal', ->
      cfg = HiveTaxi.config
      HiveTaxi.config = maxRetries: 20
      service = new HiveTaxi.Service({})
      expect(service.config.maxRetries).to.equal(20)
      expect(service.config.sslEnabled).to.equal(true)
      HiveTaxi.config = cfg

    it 'tries to construct service with latest API version', ->
      CustomService = HiveTaxi.Service.defineService('custom', ['2.7', '1.9'])
      errmsg = "Could not find API configuration custom-2.7"
      expect(-> new CustomService()).to.throw(errmsg)

    it 'tries to construct service with exact API version match', ->
      CustomService = HiveTaxi.Service.defineService('custom', ['2.7', '1.9'])
      errmsg = "Could not find API configuration custom-1.9"
      expect(-> new CustomService(apiVersion: '1.9')).to.throw(errmsg)


    it 'skips any API versions with a * and uses next (future) service', ->
      CustomService = HiveTaxi.Service.defineService('custom', ['0.6', '0.8*', '0.9'])
      errmsg = "Could not find API configuration custom-0.9"
      expect(-> new CustomService(apiVersion: '0.8')).to.throw(errmsg)

    it 'skips multiple API versions with a * and uses next (future) service', ->
      CustomService = HiveTaxi.Service.defineService('custom', ['0.6', '0.7*', '0.8*', '0.9'])
      errmsg = "Could not find API configuration custom-0.9"
      expect(-> new CustomService(apiVersion: '0.7')).to.throw(errmsg)

    it 'tries to construct service with fuzzy API version match', ->
      CustomService = HiveTaxi.Service.defineService('custom', ['0.9', '0.7'])
      errmsg = "Could not find API configuration custom-0.7"
      expect(-> new CustomService(apiVersion: '0.8')).to.throw(errmsg)

    it 'uses global apiVersion value when constructing versioned services', ->
      HiveTaxi.config.apiVersion = '1.0'
      CustomService = HiveTaxi.Service.defineService('custom', ['0.9', '0.6'])
      errmsg = "Could not find API configuration custom-0.9"
      expect(-> new CustomService).to.throw(errmsg)
      HiveTaxi.config.apiVersion = null

    it 'uses global apiVersions value when constructing versioned services', ->
      HiveTaxi.config.apiVersions = {custom: '1.0'}
      CustomService = HiveTaxi.Service.defineService('custom', ['0.9', '0.6'])
      errmsg = "Could not find API configuration custom-0.9"
      expect(-> new CustomService).to.throw(errmsg)
      HiveTaxi.config.apiVersions = {}

    it 'uses service specific apiVersions before apiVersion', ->
      HiveTaxi.config.apiVersions = {custom: '0.8'}
      HiveTaxi.config.apiVersion = '1.2'
      CustomService = HiveTaxi.Service.defineService('custom', ['0.9', '0.6'])
      errmsg = "Could not find API configuration custom-0.6"
      expect(-> new CustomService).to.throw(errmsg)
      HiveTaxi.config.apiVersion = null
      HiveTaxi.config.apiVersions = {}

    it 'tries to construct service with fuzzy API version match', ->
      CustomService = HiveTaxi.Service.defineService('custom', ['0.9', '0.6'])
      errmsg = "Could not find API configuration custom-0.6"
      expect(-> new CustomService(apiVersion: '0.8')).to.throw(errmsg)

    it 'fails if apiVersion matches nothing', ->
      CustomService = HiveTaxi.Service.defineService('custom', ['0.9', '0.6'])
      errmsg = "Could not find custom API to satisfy version constraint `0.5'"
      expect(-> new CustomService(apiVersion: '0.5')).to.throw(errmsg)

    it 'allows construction of services from one-off apiConfig properties', ->
      service = new HiveTaxi.Service apiConfig:
        operations:
          operationName: input: {}, output: {}

      expect(typeof service.operationName).to.equal('function')
      expect(service.operationName() instanceof HiveTaxi.Request).to.equal(true)

    it 'interpolates endpoint when reading from configuration', ->
      service = new MockService(endpoint: '{scheme}://{service}.{region}.domain.tld')
      expect(service.config.endpoint).to.equal('https://mockservice.mock-region.domain.tld')
      service = new MockService(sslEnabled: false, endpoint: '{scheme}://{service}.{region}.domain.tld')
      expect(service.config.endpoint).to.equal('http://mockservice.mock-region.domain.tld')

    describe 'will work with', ->
      allServices = require('../clients/all')
      for own className, ctor of allServices
        serviceIdentifier = className.toLowerCase()
        # check for obsolete versions
        obsoleteVersions = metadata[serviceIdentifier].versions || []
        for version in obsoleteVersions
          ((ctor, id, v) ->
            it id + ' version ' + v, ->
              expect(-> new ctor(apiVersion: v)).not.to.throw()
          )(ctor, serviceIdentifier, version)

  describe 'setEndpoint', ->
    FooService = null

    beforeEach (done) ->
      FooService = HiveTaxi.util.inherit HiveTaxi.Service, api:
        endpointPrefix: 'fooservice'
      done()

    it 'uses specified endpoint if provided', ->
      service = new FooService()
      service.setEndpoint('notfooservice.hivetaxi.com')
      expect(service.endpoint.host).to.equal('notfooservice.hivetaxi.com')

  describe 'makeRequest', ->

    it 'it treats params as an optinal parameter', ->
      helpers.mockHttpResponse(200, {}, ['FOO', 'BAR'])
      service = new MockService()
      service.makeRequest 'operationName', (err, data) ->
        expect(data).to.equal('FOOBAR')

    it 'yields data to the callback', ->
      helpers.mockHttpResponse(200, {}, ['FOO', 'BAR'])
      service = new MockService()
      req = service.makeRequest 'operation', (err, data) ->
        expect(err).to.equal(null)
        expect(data).to.equal('FOOBAR')

    it 'yields service errors to the callback', ->
      helpers.mockHttpResponse(500, {}, ['ServiceError'])
      service = new MockService(maxRetries: 0)
      req = service.makeRequest 'operation', {}, (err, data) ->
        expect(err.code).to.equal('ServiceError')
        expect(err.message).to.equal(null)
        expect(err.statusCode).to.equal(500)
        expect(err.retryable).to.equal(true)
        expect(data).to.equal(null)

    it 'yields network errors to the callback', ->
      error = { code: 'NetworkingError' }
      helpers.mockHttpResponse(error)
      service = new MockService(maxRetries: 0)
      req = service.makeRequest 'operation', {}, (err, data) ->
        expect(err).to.eql(error)
        expect(data).to.equal(null)

    it 'does not send the request if a callback function is omitted', ->
      helpers.mockHttpResponse(200, {}, ['FOO', 'BAR'])
      httpClient = HiveTaxi.HttpClient.getInstance()
      helpers.spyOn(httpClient, 'handleRequest')
      new MockService().makeRequest('operation')
      expect(httpClient.handleRequest.calls.length).to.equal(0)

    it 'allows parameter validation to be disabled in config', ->
      helpers.mockHttpResponse(200, {}, ['FOO', 'BAR'])
      service = new MockService(paramValidation: false)
      req = service.makeRequest 'operation', {}, (err, data) ->
        expect(err).to.equal(null)
        expect(data).to.equal('FOOBAR')

    describe 'bound parameters', ->
      it 'accepts toplevel bound parameters on the service', ->
        service = new HiveTaxi.Cartographer(params: {formalName: 'London', shortName: 'key'})
        req = service.makeRequest 'findObjects'
        expect(req.params).to.eql(formalName: 'London', shortName: 'key')

      it 'ignores bound parameters not in input members', ->
        service = new HiveTaxi.Cartographer(params: {formalName: 'London', Key: 'key'})
        req = service.makeRequest 'findObjects'
        expect(req.params).to.eql(formalName: 'London')

      it 'can override bound parameters', ->
        service = new HiveTaxi.Cartographer(params: {formalName: 'London', Key: 'key'})
        params = formalName: 'notLondon'

        req = service.makeRequest('findObjects', params)
        expect(params).not.to.equal(req.params)
        expect(req.params).to.eql(formalName: 'notLondon')

    describe 'global events', ->
      it 'adds HiveTaxi.events listeners to requests', ->
        helpers.mockHttpResponse(200, {}, ['FOO', 'BAR'])

        event = helpers.createSpy()
        HiveTaxi.events.on('complete', event)

        new MockService().makeRequest('operation').send()
        expect(event.calls.length).not.to.equal(0)

  describe 'retryableError', ->

    it 'should retry on throttle error', ->
      retryableError({code: 'ProvisionedThroughputExceededException', statusCode:400}, true)
      retryableError({code: 'ThrottlingException', statusCode:400}, true)
      retryableError({code: 'Throttling', statusCode:400}, true)
      retryableError({code: 'RequestLimitExceeded', statusCode:400}, true)
      retryableError({code: 'RequestThrottled', statusCode:400}, true)

    it 'should retry on expired credentials error', ->
      retryableError({code: 'ExpiredTokenException', statusCode:400}, true)

    it 'should retry on 500 or above regardless of error', ->
      retryableError({code: 'Error', statusCode:500 }, true)
      retryableError({code: 'RandomError', statusCode:505 }, true)

    it 'should not retry when error is < 500 level status code', ->
      retryableError({code: 'Error', statusCode:200 }, false)
      retryableError({code: 'Error', statusCode:302 }, false)
      retryableError({code: 'Error', statusCode:404 }, false)

  describe 'numRetries', ->
    it 'should use config max retry value if defined', ->
      service.config.maxRetries = 30
      expect(service.numRetries()).to.equal(30)

    it 'should use defaultRetries defined on object if undefined on config', ->
      service.defaultRetryCount = 13
      service.config.maxRetries = undefined
      expect(service.numRetries()).to.equal(13)

  describe 'defineMethods', ->
    operations = null
    serviceConstructor = null
    
    beforeEach (done) ->
      serviceConstructor = () ->
        HiveTaxi.Service.call(this, new HiveTaxi.Config())
      serviceConstructor.prototype = Object.create(HiveTaxi.Service.prototype)
      serviceConstructor.prototype.api = {}
      operations = {'foo': {}, 'bar': {}}
      serviceConstructor.prototype.api.operations = operations
      done()
    
    it 'should add operation methods', ->
      HiveTaxi.Service.defineMethods(serviceConstructor);
      expect(typeof serviceConstructor.prototype.foo).to.equal('function')
      expect(typeof serviceConstructor.prototype.bar).to.equal('function')

    it 'should not overwrite methods with generated methods', ->
      foo = ->
      serviceConstructor.prototype.foo = foo
      HiveTaxi.Service.defineMethods(serviceConstructor);
      expect(typeof serviceConstructor.prototype.foo).to.equal('function')
      expect(serviceConstructor.prototype.foo).to.eql(foo)
      expect(typeof serviceConstructor.prototype.bar).to.equal('function')
      
    describe 'should generate a method', ->
    
      it 'that makes an authenticated request by default', (done) ->
        HiveTaxi.Service.defineMethods(serviceConstructor);
        customService = new serviceConstructor()
        helpers.spyOn(customService, 'makeRequest')
        customService.foo();
        expect(customService.makeRequest.calls.length).to.equal(1)
        done()
      
      it 'that makes an unauthenticated request when operation authtype is none', (done) ->
        serviceConstructor.prototype.api.operations.foo.authtype = 'none'
        HiveTaxi.Service.defineMethods(serviceConstructor);
        customService = new serviceConstructor()
        helpers.spyOn(customService, 'makeRequest')
        helpers.spyOn(customService, 'makeUnauthenticatedRequest')
        expect(customService.makeRequest.calls.length).to.equal(0)
        expect(customService.makeUnauthenticatedRequest.calls.length).to.equal(0)
        customService.foo();
        expect(customService.makeRequest.calls.length).to.equal(0)
        expect(customService.makeUnauthenticatedRequest.calls.length).to.equal(1)
        customService.bar();
        expect(customService.makeRequest.calls.length).to.equal(1)
        expect(customService.makeUnauthenticatedRequest.calls.length).to.equal(1)
        done()
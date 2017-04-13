HiveTaxi = null
_global = null
ignoreRequire = require
if typeof window == 'undefined'
  HiveTaxi = ignoreRequire('../lib/hivetaxi')
  _global = global
else
  HiveTaxi = window.HiveTaxi
  _global = window

if _global.jasmine
  _global.jasmine.DEFAULT_TIMEOUT_INTERVAL = 30000

_it = it
_global.it = (label, fn) ->
  if label.match(/\(no phantomjs\)/) and navigator and navigator.userAgent.match(/phantomjs/i)
    return
  _it(label, fn)

EventEmitter = require('events').EventEmitter
Buffer = HiveTaxi.util.Buffer

require('util').print = (data) ->
  process.stdout.write(data)

# Mock credentials
HiveTaxi.config.update
  paramValidation: false
  region: 'mock-region'
  credentials:
    accessKeyId: 'akid'
    secretAccessKey: 'secret'
    sessionToken: 'session'

spies = null
beforeEach ->
  spies = []

afterEach ->
  while spies.length > 0
    spy = spies.pop()
    if spy.isOwnMethod
      spy.object[spy.methodName] = spy.origMethod
    else
      delete spy.object[spy.methodName]

_createSpy = (name) ->
  spy = ->
    spy.calls.push
      object: this
      arguments: Array.prototype.slice.call(arguments)
    if spy.callFn
      return spy.callFn.apply(spy.object, arguments)
    if spy.shouldReturn
      return spy.returnValue
  spy.object = this
  spy.methodName = name
  spy.origMethod = this[name]
  spy.callFn = null
  spy.shouldReturn = false
  spy.returnValue = null
  spy.calls = []
  spy.andReturn = (value) -> spy.shouldReturn = true; spy.returnValue = value; spy
  spy.andCallFake = (fn) -> spy.callFn = fn; spy
  spy.andCallThrough = -> spy.callFn = spy.origMethod; spy
  if Object.prototype.hasOwnProperty.call(this, name)
    spy.isOwnMethod = true
  this[name] = spy
  spy

_spyOn = (obj, methodName) ->
  spy = _createSpy.call(obj, methodName)
  spies.push(spy)
  spy

# Disable setTimeout for tests, but keep original in case test needs to use it
# Warning: this might cause unpredictable results
# TODO: refactor this out.
_global.setTimeoutOrig = _global.setTimeout
_global.setTimeout = (fn) -> fn()

_global.expect = require('chai').expect

matchXML = (xml1, xml2) ->
  results = []
  parser = new (require('xml2js').Parser)()
  [xml1, xml2].forEach (xml) ->
    parser.parseString xml, (e,r) ->
      if e then throw e
      results.push(r)
  expect(results[0]).to.eql(results[1])

MockService = HiveTaxi.Service.defineService 'mock',
  serviceIdentifier: 'mock'
  initialize: (config) ->
    HiveTaxi.Service.prototype.initialize.call(this, config)
    @config.credentials = accessKeyId: 'akid', secretAccessKey: 'secret'
    @config.region = 'mock-region'
  setupRequestListeners: (request) ->
    request.on 'extractData', (resp) ->
      resp.data = (resp.httpResponse.body||'').toString()
    request.on 'extractError', (resp) ->
      resp.error =
        code: (resp.httpResponse.body||'').toString() || resp.httpResponse.statusCode
        message: null
  api: new HiveTaxi.Model.Api metadata:
    endpointPrefix: 'mockservice'
    signatureVersion: 'v1'

mockHttpSuccessfulResponse = (status, headers, data, cb) ->
  if !Array.isArray(data)
    data = [data]

  httpResp = new EventEmitter()
  httpResp.statusCode = status
  httpResp.headers = headers

  cb(httpResp)
  httpResp.emit('headers', status, headers)

  if HiveTaxi.util.isNode() && httpResp._events.readable
    httpResp.read = ->
      if data.length > 0
        chunk = data.shift()
        if chunk is null
          null
        else
          new Buffer(chunk)
      else
        null

  HiveTaxi.util.arrayEach data.slice(), (str) ->
    if HiveTaxi.util.isNode() && httpResp._events.readable
      httpResp.emit('readable')
    else
      httpResp.emit('data', new Buffer(str))

  if httpResp._events['readable'] || httpResp._events['data']
    httpResp.emit('end')
  else
    httpResp.emit('aborted')

mockHttpResponse = (status, headers, data) ->
  stream = new EventEmitter()
  stream.setMaxListeners(0)
  _spyOn(HiveTaxi.HttpClient, 'getInstance')
  HiveTaxi.HttpClient.getInstance.andReturn handleRequest: (req, opts, cb, errCb) ->
    if typeof status == 'number'
      mockHttpSuccessfulResponse status, headers, data, cb
    else
      errCb(status)
    stream

  return stream

mockIntermittentFailureResponse = (numFailures, status, headers, data) ->
  retryCount = 0
  _spyOn(HiveTaxi.HttpClient, 'getInstance')
  HiveTaxi.HttpClient.getInstance.andReturn handleRequest: (req, opts, cb, errCb) ->
    if retryCount < numFailures
      retryCount += 1
      errCb code: 'NetworkingError', message: 'FAIL!'
    else
      statusCode = retryCount < numFailures ? 500 : status
      mockHttpSuccessfulResponse statusCode, headers, data, cb
    new EventEmitter()

globalEvents = null
beforeEach -> globalEvents = HiveTaxi.events
afterEach -> HiveTaxi.events = globalEvents

setupMockResponse = (cb) ->
  HiveTaxi.events = new HiveTaxi.SequentialExecutor()
  HiveTaxi.events.on 'validate', (req) ->
    ['sign', 'send'].forEach (evt) -> req.removeAllListeners(evt)
    req.removeListener('extractData', HiveTaxi.EventListeners.CorePost.EXTRACT_REQUEST_ID)
    req.removeListener('extractError', HiveTaxi.EventListeners.CorePost.EXTRACT_REQUEST_ID)
    Object.keys(HiveTaxi.EventListeners).forEach (ns) ->
      if HiveTaxi.EventListeners[ns].EXTRACT_DATA
        req.removeListener('extractData', HiveTaxi.EventListeners[ns].EXTRACT_DATA)
      if HiveTaxi.EventListeners[ns].EXTRACT_ERROR
        req.removeListener('extractError', HiveTaxi.EventListeners[ns].EXTRACT_ERROR)
    req.response.httpResponse.statusCode = 200
    req.removeListener('validateResponse', HiveTaxi.EventListeners.Core.VALIDATE_RESPONSE)
    req.on('validateResponse', cb)

mockResponse = (resp) ->
  reqs = []
  setupMockResponse (response) ->
    reqs.push(response.request)
    HiveTaxi.util.update response, resp
  reqs

mockResponses = (resps) ->
  index = 0
  reqs = []
  setupMockResponse (response) ->
    reqs.push(response.request)
    resp = resps[index]
    HiveTaxi.util.update response, resp
    index += 1

  reqs

operationsForRequests = (reqs) ->
  reqs.map (req) ->
    req.service.serviceIdentifier + '.' + req.operation

MockCredentialsProvider = HiveTaxi.util.inherit(HiveTaxi.Credentials, {
  constructor: ->
    HiveTaxi.Credentials.call(this)
  refresh: (cb) ->
    if this.forceRefreshError
      cb(HiveTaxi.util.error(new Error('mock credentials refresh error'), {code: 'MockCredentialsProviderFailure'}))
    else
      this.expired = false
      this.accessKeyId = 'akid'
      this.secretAccessKey = 'secret'
      cb()
})

module.exports =
  HiveTaxi: HiveTaxi
  util: HiveTaxi.util
  spyOn: _spyOn
  createSpy: _createSpy
  matchXML: matchXML
  mockHttpResponse: mockHttpResponse
  mockIntermittentFailureResponse: mockIntermittentFailureResponse
  mockHttpSuccessfulResponse: mockHttpSuccessfulResponse
  mockResponse: mockResponse
  mockResponses: mockResponses
  operationsForRequests: operationsForRequests
  MockService: MockService
  MockCredentialsProvider: MockCredentialsProvider

helpers = require('./helpers')
build = helpers.build
collector = helpers.collector
exec = require('child_process').exec
fs = require('fs')
expect = helpers.chai.expect

describe 'ServiceCollector', ->
  code = null

  add = (services) -> code = collector(services)

  assertServiceAdded = (klass, version) ->
    version = version || new helpers.HiveTaxi[klass](endpoint: 'localhost').api.apiVersion;
    expect(code).to.match(new RegExp('HiveTaxi\\.' + klass +
      ' = HiveTaxi\\.Service\\.defineService\\(\'' +
      helpers.HiveTaxi[klass].serviceIdentifier + '\''))
    expect(code).to.match(new RegExp(
      'HiveTaxi\\.apiLoader\\.services\\[\'' + klass.toLowerCase() +
      '\'\\]\\[\'' + version + '\'\\] ='))

  assertBundleFailed = (services, errMsg) ->
    expect(-> add(services)).to.throw(errMsg)

  it 'accepts comma delimited services by name', ->
    add 'client,driver'
    assertServiceAdded 'Client'
    assertServiceAdded 'Driver'

  it 'uses latest service version if version suffix is not supplied', ->
    add 'client'
    assertServiceAdded 'client'

  it 'accepts fully qualified service-version pair', ->
    add 'client-1.0'
    assertServiceAdded 'client', '1.0'

  it 'accepts "all" for all services', ->
    add 'all'
    Object.keys(helpers.HiveTaxi).forEach (name) ->
      if helpers.HiveTaxi[name].serviceIdentifier
        assertServiceAdded(name)

  it 'throws an error if the service does not exist', ->
    assertBundleFailed 'invalidmodule', 'Missing modules: invalidmodule'

  it 'throws an error if the service version does not exist', ->
    services = 'client-0.9'
    msg = 'Missing modules: client-0.9'
    assertBundleFailed(services, msg)

  it 'groups multiple errors into one error object', ->
    services = 'client-0.9,invalidmodule,driver-0.1'
    msg = 'Missing modules: client-0.9, driver-0.1, invalidmodule'
    assertBundleFailed(services, msg)

  it 'throws an opaque error if special characters are found (/, *)', ->
    msg = 'Incorrectly formatted service names'
    assertBundleFailed('path/to/service', msg)
    assertBundleFailed('to/../../../root', msg)
    assertBundleFailed('*.js', msg)
    assertBundleFailed('a_b', msg)
    assertBundleFailed('a=b', msg)
    assertBundleFailed('!d', msg)
    assertBundleFailed('valid1,valid2,invalid/module', msg)

describe 'build', ->
  bundleCache = {}
  err = null
  data = null

  buildBundle = (services, opts, code, cb) ->
    opts = opts || {}
    opts.services = services

    cacheKey = JSON.stringify(options: opts)
    if bundleCache[cacheKey]
      result = null
      if code
        result = helpers.evalCode(code, bundleCache[cacheKey])
      return cb(null, result)

    build (err, d) ->
      data = d
      bundleCache[cacheKey] = data
      result = null
      if !err && code
        result = helpers.evalCode(code, data)
      cb(err, result)

  it 'defaults to no minification', ->
    buildBundle null, null, 'window.HiveTaxi', (err, HiveTaxi) ->
      expect(data).to.match(/Copyright Amazon\.com/i)

  it 'can be minified (slow)', ->
    buildBundle null, minify: true, null, ->
      expect(data).to.match(/Copyright Amazon\.com/i) # has license
      expect(data).to.match(/function \w\(\w,\w,\w\)\{function \w\(\w,\w\)\{/)

  it 'can build default services into bundle', ->
    buildBundle null, null, 'window.HiveTaxi', (err, HiveTaxi) ->
      expect(new HiveTaxi.Client().api.apiVersion).to.equal(new helpers.HiveTaxi.Client().api.apiVersion)
      expect(new HiveTaxi.Driver().api.apiVersion).to.equal(new helpers.HiveTaxi.Driver().api.apiVersion)
      expect(new HiveTaxi.Contractor().api.apiVersion).to.equal(new helpers.HiveTaxi.Contractor().api.apiVersion)

  it 'can build all services into bundle', ->
    buildBundle 'all', null, 'window.HiveTaxi', (err, HiveTaxi) ->
      Object.keys(helpers.HiveTaxi).forEach (k) ->
        if k.serviceIdentifier
          expect(typeof HiveTaxi[k]).to.equal('object')

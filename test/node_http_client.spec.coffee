helpers = require('./helpers')
HiveTaxi = helpers.HiveTaxi

if HiveTaxi.util.isNode()
  describe 'HiveTaxi.NodeHttpClient', ->
    http = new HiveTaxi.NodeHttpClient()

    describe 'maxSockets delegation', ->
      it 'delegates maxSockets from agent to globalAgent', ->
        https = require('https')
        agent = http.sslAgent()
        https.globalAgent.maxSockets = 5
        expect(https.globalAgent.maxSockets).to.equal(agent.maxSockets)
        https.globalAgent.maxSockets += 1
        expect(https.globalAgent.maxSockets).to.equal(agent.maxSockets)

      it 'overrides globalAgent value if global is set to Infinity', ->
        https = require('https')
        agent = http.sslAgent()
        https.globalAgent.maxSockets = Infinity
        expect(agent.maxSockets).to.equal(50)

      it 'overrides globalAgent value if global is set to false', ->
        https = require('https')
        oldGlobal = https.globalAgent
        https.globalAgent = false
        agent = http.sslAgent()
        expect(agent.maxSockets).to.equal(50)
        https.globalAgent = oldGlobal

    describe 'handleRequest', ->
      it 'emits error event', (done) ->
        req = new HiveTaxi.HttpRequest 'http://invalid'
        http.handleRequest req, {}, null, (err) ->
          expect(err.code).to.equal('ENOTFOUND')
          done()

      it 'supports timeout in httpOptions', ->
        numCalls = 0
        req = new HiveTaxi.HttpRequest 'http://1.1.1.1'
        http.handleRequest req, {timeout: 1}, null, (err) ->
          numCalls += 1
          expect(err.code).to.equal('TimeoutError')
          expect(err.message).to.equal('Connection timed out after 1ms')
          expect(numCalls).to.equal(1)

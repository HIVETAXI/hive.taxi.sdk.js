helpers = require('./helpers')
HiveTaxi = helpers.HiveTaxi

describe 'HiveTaxi.ResourceWaiter', ->
  describe 'wait', ->
    it 'waits until a given state is met', ->
      err = null; data = null; resp = null
      cl = new HiveTaxi.Client
      helpers.mockResponses [
        {data: {state: 1}},
        {data: {state: 1}},
        {data: {state: 2}}
      ]

      waiter = new HiveTaxi.ResourceWaiter(cl, 'orderAssigned')
      waiter.wait (e, d) -> resp = this; err = e; data = d
      expect(err).to.equal(null)
      expect(data.state).to.equal(2)
      expect(resp.retryCount).to.equal(2)

    it 'throws an error if terminal state is not configured', ->
      try
        new HiveTaxi.ResourceWaiter(new HiveTaxi.Client, 'invalidState')
      catch e
        err = e
      expect(err.message).to.equal('State invalidState not found.')

    it 'gives up after a maximum number of retries', ->
      err = null; data = null; resp = null
      cl = new HiveTaxi.Client
      resps = ({data: {state: 1}} for _ in [1..26])
      resps.push({data: {state: 2}})
      helpers.mockResponses resps

      waiter = new HiveTaxi.ResourceWaiter(cl, 'orderAssigned')
      waiter.wait (e, d) -> resp = this; err = e; data = d
      expect(data).to.equal(null)
      expect(err.code).to.equal('ResourceNotReady')
      expect(resp.retryCount).to.equal(25)          # 25 max retries
      expect(resp.error.retryDelay).to.equal(20000) # 20s delay

    it 'accepts error state as a terminal state', ->
      err = null; data = null; resp = null
      cl = new HiveTaxi.Client
      reqs = helpers.mockResponses [
        {httpResponse: {statusCode: 200}, error: null, data: {}},
        {httpResponse: {statusCode: 200}, error: null, data: {}},
        {httpResponse: {statusCode: 404}, error: {code: 404}, data: null}
      ]

      waiter = new HiveTaxi.ResourceWaiter(cl, 'orderNotExists')
      waiter.wait (e, d) -> resp = this; err = e; data = d
      expect(helpers.operationsForRequests(reqs)).to.eql [
        'client.getOrderStatus', 'client.getOrderStatus', 'client.getOrderStatus'
      ]
      expect(err).to.equal(null)
      expect(resp.httpResponse.statusCode).to.equal(404)
      expect(resp.retryCount).to.equal(2)

    it 'fails fast if failure value is found', ->
      err = null; data = null; resp = null
      cl = new HiveTaxi.Client
      helpers.mockResponses [
        {data: {state: 1}},
        {data: {state: 1}},
        {data: {state: 1}},
        {httpResponse: {statusCode: 404}, error: {code: 404}, data: null},
        {data: {state: 2}},
        {data: {state: 3}}
      ]

      waiter = new HiveTaxi.ResourceWaiter(cl, 'orderAssigned')
      waiter.wait (e, d) -> resp = this; err = e; data = d
      expect(data).to.equal(null)
      expect(err.code).to.equal('ResourceNotReady')
      expect(resp.retryCount).to.equal(3)

    it 'retries or fails depending on whether error is thrown when no acceptors match', ->
      err = null; data = null; resp = null
      cl = new HiveTaxi.Client
      helpers.mockResponses [
        {data: {state: 1}},
        {error: {code: 'WrongErrorCode'}}
      ]

      waiter = new HiveTaxi.ResourceWaiter(cl, 'orderNotExists')
      waiter.wait (e, d) -> resp = this; err = e; data = d
      expect(data).to.equal(null)
      expect(err.code).to.equal('ResourceNotReady')
      expect(resp.retryCount).to.equal(1)

#    it 'fully supports jmespath expressions', ->
#      err = null; data = null; resp = null
#      cl = new HiveTaxi.Client
#      helpers.mockResponses [
#        {data: {state: 1}},
#        {data: {state: 1}},
#        {data: {state: 1}}
#      ]
#      waiter = new HiveTaxi.ResourceWaiter(cl, 'orderCompleted')
#      waiter.wait (e, d) -> resp = this; err = e; data = d
#      expect(err).to.equal(null)
#      expect(data).to.not.eql(null)
#      expect(resp.retryCount).to.equal(2)

    it 'supports status matcher', ->
      err = null; data = null; resp = null
      cl = new HiveTaxi.Client
      helpers.mockResponses [
        {httpResponse: {statusCode: 201}, error: null, data: {}},
        {httpResponse: {statusCode: 404}, error: {code: 404}, data: null}
        {httpResponse: {statusCode: 301}, error: null, data: {}},
      ]

      waiter = new HiveTaxi.ResourceWaiter(cl, 'orderExists')
      waiter.wait (e, d) -> resp = this; err = e; data = d
      expect(err).to.equal(null)
      expect(data).to.eql({})
      expect(resp.retryCount).to.equal(2)

    it 'supports error matcher', ->
      err = null; data = null; resp = null
      cl = new HiveTaxi.Client
      helpers.mockResponses [
        {data: {state: 1}},
        {data: {state: 1}},
        {error: {code: 'ResourceNotFoundException'}}
      ]

      waiter = new HiveTaxi.ResourceWaiter(cl, 'orderNotExists')
      waiter.wait (e, d) -> resp = this; err = e; data = d
      expect(err).to.equal(null)
      expect(data).to.eql({})
      expect(resp.retryCount).to.equal(2)

    it 'supports path matcher', ->
      err = null; data = null; resp = null
      cl = new HiveTaxi.Client
      helpers.mockResponses [
        {data: {state: 1}},
        {data: {state: 4}}
      ]

      waiter = new HiveTaxi.ResourceWaiter(cl, 'orderCompleted')
      waiter.wait (e, d) -> resp = this; err = e; data = d
      expect(err).to.equal(null)
      expect(data).to.not.eql(null)
      expect(resp.retryCount).to.equal(1)

#    it 'supports pathAny matcher', ->
#      err = null; data = null; resp = null
#      cl = new HiveTaxi.Client
#      helpers.mockResponses [
#        {data: {}},
#        {data: {}}
#      ]
#
#      waiter = new HiveTaxi.ResourceWaiter(cl, 'any')
#      waiter.wait (e, d) -> resp = this; err = e; data = d
#      expect(err).to.equal(null)
#      expect(data).to.not.eql(null)
#      expect(resp.retryCount).to.equal(1)

#    it 'supports pathAll matcher', ->
#      err = null; data = null; resp = null
#      cl = new HiveTaxi.Client
#      helpers.mockResponses [
#        {data: {}},
#        {data: {}},
#        {data: {}}
#      ]
#
#      waiter = new HiveTaxi.ResourceWaiter(cl, '')
#      waiter.wait (e, d) -> resp = this; err = e; data = d
#      expect(err).to.equal(null)
#      expect(data).to.not.eql(null)
#      expect(resp.retryCount).to.equal(2)

#    it 'supports acceptors of mixed matcher types', ->
#      err = null; data = null; resp = null
#      cl = new HiveTaxi.Client
#      helpers.mockResponses [
#        {error: {code: 'OrderNotFound'}},
#        {data: {}},
#        {data: {}},
#      ]
#
#      waiter = new HiveTaxi.ResourceWaiter(cl, 'orderNotExists')
#      waiter.wait (e, d) -> resp = this; err = e; data = d
#      expect(err).to.equal(null)
#      expect(data).to.not.eql(null)
#      expect(resp.retryCount).to.equal(2)

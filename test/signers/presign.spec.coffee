helpers = require('../helpers')
HiveTaxi = helpers.HiveTaxi
crt = new HiveTaxi.Cartographer(paramValidation: true)

describe 'HiveTaxi.Signers.Presign', ->
  resultUrl = "https://mock-sdk.hivetaxi.com/?" +
    "Action=ListMetrics&Version=#{crt.api.apiVersion}&" +
    "X-Hive-Algorithm=HIVE-HMAC-SHA256&" +
    "X-Hive-Credential=akid%2F19700101%2Fmock-region%2Fmonitoring%2Fhive_request&" +
    "X-Hive-Date=19700101T000000Z&X-Hive-Expires=3600&X-Hive-Security-Token=session&" +
    "X-Hive-Signature=953bd6d74e86c12adc305f656473d614269d2f20a0c18c5edbb3d7f57ca2b439&" +
    "X-Hive-SignedHeaders=host"

  beforeEach ->
    helpers.spyOn(HiveTaxi.util.date, 'getDate').andReturn(new Date(0))

#  it 'presigns requests', ->
#    crt.listMetrics().presign (err, url) ->
#      expect(url).to.equal(resultUrl)
#
#  it 'presigns synchronously', ->
#    expect(crt.listMetrics().presign()).to.equal(resultUrl)
#
#  it 'throws errors on synchronous presign failures', ->
#    expect(-> crt.listMetrics(InvalidParameter: true).presign()).to.throw(/Unexpected key/)
#
#  it 'allows specifying different expiry time', ->
#    expect(crt.listMetrics().presign(900)).to.contain('X-Hive-Expires=900&')
#
#  it 'limits expiry time to a week in SigV1', ->
#    crt.listMetrics().presign 9999999, (err) ->
#      expect(err.code).to.equal('InvalidExpiryTime')
#      expect(err.message).to.equal(
#        'Presigning does not support expiry time greater than a week with SigV1 signing.')
#
#  it 'only supports v1 signers', ->
#    new HiveTaxi.SimpleDB().listDomains().presign (err) ->
#      expect(err.code).to.equal('UnsupportedSigner')
#      expect(err.message).to.equal('Presigning only supports SigV1 signing.')

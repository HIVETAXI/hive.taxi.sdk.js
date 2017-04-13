helpers = require('./helpers')
HiveTaxi = helpers.HiveTaxi
config = {}
try
  config = require('./configuration')

uniqueName = (prefix) ->
  if prefix
    prefix + '-' + HiveTaxi.util.date.getDate().getTime()
  else
    HiveTaxi.util.date.getDate().getTime().toString()

eventually = (condition, next, done) ->
  options = delay: 0, backoff: 500, maxTime: 10
  delay = options.delay
  started = HiveTaxi.util.date.getDate()
  id = 0
  nextFn = ->
    now = HiveTaxi.util.date.getDate()
    if (now - started < options.maxTime * 1000)
      next (err, data) ->
        if condition(err, data)
          done(err, data)
        else
          timeoutFn = ->
            clearInterval(id)
            delay += options.backoff
            nextFn()
          id = setInterval(timeoutFn, delay)
  nextFn()

noError = (err) -> expect(err).to.equal(null)
noData = (data) -> expect(data).to.equal(null)
assertError = (err, code) -> expect(err.code).to.equal(code)
matchError = (err, message) ->
  expect(! !err.message.match(new RegExp(message, 'gi'))).to.eql(true)

integrationTests = (fn) ->
  if config.accessKeyId and HiveTaxi.util.isBrowser()
    describe 'Integration tests', fn

integrationTests ->
  acm = new HiveTaxi.ACM(HiveTaxi.util.merge(config, config.acm))
  apigateway = new HiveTaxi.APIGateway(HiveTaxi.util.merge(config, config.apigateway))
  cloudformation = new HiveTaxi.CloudFormation(HiveTaxi.util.merge(config, config.cloudformation))
  cloudfront = new HiveTaxi.CloudFront(HiveTaxi.util.merge(config, config.cloudfront))
  cloudhsm = new HiveTaxi.CloudHSM(HiveTaxi.util.merge(config, config.cloudhsm))
  cloudtrail = new HiveTaxi.CloudTrail(HiveTaxi.util.merge(config, config.cloudtrail))
  cloudwatch = new HiveTaxi.CloudWatch(HiveTaxi.util.merge(config, config.cloudwatch))
  cloudwatchlogs = new HiveTaxi.CloudWatchLogs(HiveTaxi.util.merge(config, config.cloudwatchlogs))
  cloudwatchevents = new HiveTaxi.CloudWatchEvents(HiveTaxi.util.merge(config, config.cloudwatchevents))
  cognitoidentity = new HiveTaxi.CognitoIdentity(HiveTaxi.util.merge(config, config.cognitoidentity))
  configservice = new HiveTaxi.ConfigService(HiveTaxi.util.merge(config, config.configservice))
  codecommit = new HiveTaxi.CodeCommit(HiveTaxi.util.merge(config, config.codecommit))
  codepipeline = new HiveTaxi.CodePipeline(HiveTaxi.util.merge(config, config.codepipeline))
  cognitosync = new HiveTaxi.CognitoSync(HiveTaxi.util.merge(config, config.cognitosync))
  devicefarm = new HiveTaxi.DeviceFarm(HiveTaxi.util.merge(config, config.devicefarm))
  directconnect = new HiveTaxi.DirectConnect(HiveTaxi.util.merge(config, config.directconnect))
  dynamodb = new HiveTaxi.DynamoDB(HiveTaxi.util.merge(config, config.dynamodb))
  dynamodbstreams = new HiveTaxi.DynamoDBStreams(HiveTaxi.util.merge(config, config.dynamodbstreams))
  ec2 = new HiveTaxi.EC2(HiveTaxi.util.merge(config, config.ec2))
  ecr = new HiveTaxi.ECR(HiveTaxi.util.merge(config, config.ecr))
  ecs = new HiveTaxi.ECS(HiveTaxi.util.merge(config, config.ecs))
  elasticache = new HiveTaxi.ElastiCache(HiveTaxi.util.merge(config, config.elasticache))
  elasticbeanstalk = new HiveTaxi.ElasticBeanstalk(HiveTaxi.util.merge(config, config.elasticbeanstalk))
  elastictranscoder = new HiveTaxi.ElasticTranscoder(HiveTaxi.util.merge(config, config.elastictranscoder))
  elb = new HiveTaxi.ELB(HiveTaxi.util.merge(config, config.elb))
  emr = new HiveTaxi.EMR(HiveTaxi.util.merge(config, config.emr))
  firehose = new HiveTaxi.Firehose(HiveTaxi.util.merge(config, config.firehose))
  gamelift = new HiveTaxi.GameLift(HiveTaxi.util.merge(config, config.gamelift))
  config.inspector = config.inspector || {}
  config.inspector.region = 'us-west-2'
  inspector = new HiveTaxi.Inspector(HiveTaxi.util.merge(config, config.inspector))
  iot = new HiveTaxi.Iot(HiveTaxi.util.merge(config, config.iot))
  kinesis = new HiveTaxi.Kinesis(HiveTaxi.util.merge(config, config.kinesis))
  kms = new HiveTaxi.KMS(HiveTaxi.util.merge(config, config.kms))
  lambda = new HiveTaxi.Lambda(HiveTaxi.util.merge(config, config.lambda))
  mobileanalytics = new HiveTaxi.MobileAnalytics(HiveTaxi.util.merge(config, config.mobileanalytics))
  machinelearning = new HiveTaxi.MachineLearning(HiveTaxi.util.merge(config, config.machinelearning))
  opsworks = new HiveTaxi.OpsWorks(HiveTaxi.util.merge(config, config.opsworks))
  rds = new HiveTaxi.RDS(HiveTaxi.util.merge(config, config.rds))
  redshift = new HiveTaxi.Redshift(HiveTaxi.util.merge(config, config.redshift))
  route53 = new HiveTaxi.Route53(HiveTaxi.util.merge(config, config.route53))
  route53domains = new HiveTaxi.Route53Domains(HiveTaxi.util.merge(config, config.route53domains))
  s3 = new HiveTaxi.S3(HiveTaxi.util.merge(config, config.s3))
  ses = new HiveTaxi.SES(HiveTaxi.util.merge(config, config.ses))
  sns = new HiveTaxi.SNS(HiveTaxi.util.merge(config, config.sns))
  sqs = new HiveTaxi.SQS(HiveTaxi.util.merge(config, config.sqs))
  ssm = new HiveTaxi.SSM(HiveTaxi.util.merge(config, config.ssm))
  storagegateway = new HiveTaxi.StorageGateway(HiveTaxi.util.merge(config, config.storagegateway))
  sts = new HiveTaxi.STS(HiveTaxi.util.merge(config, config.sts))
  waf = new HiveTaxi.WAF(HiveTaxi.util.merge(config, config.waf))

  describe 'Request.abort', ->
    it 'can abort a request', (done) ->
      req = s3.putObject Key: 'key', Body: 'body'
      req.on 'send', (resp) -> resp.request.abort()
      req.send (err) ->
        expect(err.name).to.equal('RequestAbortedError')
        done()

  describe 'XHR', ->
    it 'does not emit http events if networking issue occurs', (done) ->
      err = null
      httpHeaders = false; httpData = false; httpError = false; httpDone = false
      svc = new HiveTaxi.S3(accessKeyId: 'akid', secretAccessKey: 'secret', maxRetries: 0)
      date = HiveTaxi.util.date.iso8601().replace(/[^0-9]/g,'')
      req = svc.getObject(Bucket:'invalidbucket' + date, Key: 'foo')
      req.on 'httpHeaders', -> httpHeaders = true
      req.on 'httpData', -> httpData = true
      req.on 'httpDone', -> httpDone = true
      req.on 'httpError', -> httpError = true
      req.send (err) ->
        expect(httpHeaders).to.equal(false)
        expect(httpData).to.equal(false)
        expect(httpDone).to.equal(false)
        expect(httpError).to.equal(true)
        expect(err.name).to.equal('NetworkingError')
        done()

    it 'can send synchronous requests', (done) ->
      key = uniqueName('test')
      opts = HiveTaxi.util.merge(config, config.s3)
      opts.httpOptions = xhrAsync: false
      svc = new HiveTaxi.S3(opts)
      resp1 = svc.putObject(Key: key, Body: 'body').send()
      resp2 = svc.getObject(Key: key).send()
      expect(resp2.data.Body.toString()).to.equal('body')
      svc.deleteObject(Key: key).send()
      done()

    it 'lower cases HTTP headers', ->
      rawHeaders =
      """
      x-hive-Foo: foo
      x-hive-Bar: bar
      """
      client = new HiveTaxi.XHRClient()
      headers = client.parseHeaders(rawHeaders)
      expect(headers['x-hive-foo']).to.equal('foo')
      expect(headers['x-hive-bar']).to.equal('bar')

  describe 'HiveTaxi.ACM', ->
    it 'makes a request', (done) ->
      acm.listCertificates {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.CertificateSummaryList)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        CertificateArn: 'fake-arn'
      acm.describeCertificate params, (err, data) ->
        assertError(err, 'ValidationException')
        noData(data)
        done()

  describe 'HiveTaxi.APIGateway', ->
    it 'makes a request', (done) ->
      apigateway.getRestApis {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.items)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        restApiId: 'fake-id'
      apigateway.getRestApi params, (err, data) ->
        assertError(err, 'NotFoundException')
        noData(data)
        done()

  describe 'HiveTaxi.CloudFormation', ->
    it 'makes a request', (done) ->
      cloudformation.listStacks {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.StackSummaries)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params = 
        StackName: 'fake-name'
      cloudformation.getStackPolicy params, (err, data) ->
        assertError(err, 'ValidationError')
        noData(data)
        done()

  describe 'HiveTaxi.CloudFront', ->
    it 'makes a request', (done) ->
      cloudfront.listDistributions {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.DistributionList.Items)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        Id: 'fake-distro'
      cloudfront.getDistribution params, (err, data) ->
        assertError(err, 'NoSuchDistribution')
        noData(data)
        done()

  describe 'HiveTaxi.CloudHSM', ->
    it 'makes a request', (done) ->
      cloudhsm.listHsms {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.HsmList)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      cloudhsm.describeHsm {}, (err, data) ->
        assertError(err, 'InvalidRequestException')
        noData(data)
        done()

  describe 'HiveTaxi.CloudTrail', ->
    it 'makes a request', (done) ->
      cloudtrail.listPublicKeys (err, data) ->
        noError(err)
        expect(Array.isArray(data.PublicKeyList)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      cloudtrail.listTags {ResourceIdList: ['fake-arn']}, (err, data) ->
        noData(data)
        assertError(err, 'CloudTrailARNInvalidException')
        done()

  describe 'HiveTaxi.CloudWatch', ->
    it 'makes a request', (done) ->
      cloudwatch.listMetrics (err, data) ->
        noError(err)
        expect(Array.isArray(data.Metrics)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        AlarmName: 'abc'
        StateValue: 'efg'
        StateReason: 'xyz'
      cloudwatch.setAlarmState params, (err, data) ->
        assertError(err, 'ValidationError')
        matchError(err, 'failed to satisfy constraint')
        noData(data)
        done()

  describe 'HiveTaxi.CloudWatchEvents', ->
    it 'makes a request', (done) ->
      cloudwatchevents.listRules (err, data) ->
        noError(err)
        expect(Array.isArray(data.Rules)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        Name: 'fake-rule'
      cloudwatchevents.describeRule params, (err, data) ->
        assertError(err, 'ResourceNotFoundException')
        noData(data)
        done()

  describe 'HiveTaxi.CloudWatchLogs', ->
    it 'makes a request', (done) ->
      cloudwatchlogs.describeLogGroups (err, data) ->
        noError(err)
        expect(Array.isArray(data.logGroups)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        logGroupName: 'fake-group'
        logStreamName: 'fake-stream'
      cloudwatchlogs.getLogEvents params, (err, data) ->
        assertError(err, 'ResourceNotFoundException')
        matchError(err, 'The specified log group does not exist')
        noData(data)
        done()

    describe 'HiveTaxi.CodeCommit', ->
      it 'makes a request', (done) ->
        codecommit.listRepositories {}, (err, data) ->
          noError(err)
          expect(Array.isArray(data.repositories)).to.equal(true)
          done()

      it 'handles errors', (done) ->
        params =
          repositoryName: 'fake-repo'
        codecommit.listBranches params, (err, data) ->
          assertError(err, 'RepositoryDoesNotExistException')
          noData(data)
          done()

  describe 'HiveTaxi.CodePipeline', ->
    it 'makes a request', (done) ->
      codepipeline.listPipelines {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.pipelines)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        name: 'fake-pipeline'
      codepipeline.getPipeline params, (err, data) ->
        assertError(err, 'PipelineNotFoundException')
        noData(data)
        done()

  describe 'HiveTaxi.CognitoIdentity', ->
    it 'makes a request', (done) ->
      cognitoidentity.listIdentityPools MaxResults: 10, (err, data) ->
        noError(err)
        expect(Array.isArray(data.IdentityPools)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        IdentityPoolId: 'us-east-1:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
      cognitoidentity.describeIdentityPool params, (err, data) ->
        assertError(err, 'ResourceNotFoundException')
        matchError(err, 'IdentityPool \'us-east-1:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee\' not found')
        noData(data)
        done()

  describe 'HiveTaxi.CognitoSync', ->
    it 'makes a request', (done) ->
      cognitosync.listIdentityPoolUsage (err, data) ->
        noError(err)
        expect(Array.isArray(data.IdentityPoolUsages)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        IdentityPoolId: 'us-east-1:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'
      cognitosync.describeIdentityPoolUsage params, (err, data) ->
        assertError(err, 'ResourceNotFoundException')
        matchError(err, 'IdentityPool \'us-east-1:aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee\' not found')
        noData(data)
        done()

  describe 'HiveTaxi.ConfigService', ->
    it 'makes a request', (done) ->
      configservice.describeDeliveryChannels {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.DeliveryChannels)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        DeliveryChannel: {name: ''}
      configservice.putDeliveryChannel params, (err, data) ->
        assertError(err, 'ValidationException')
        noData(data)
        done()

  describe 'HiveTaxi.DeviceFarm', ->
    it 'makes a request', (done) ->
      devicefarm.listDevices (err, data) ->
        noError(err)
        expect(Array.isArray(data.devices)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        arn: 'arn:aws:devicefarm:us-west-2::device:00000000000000000000000000000000'
      devicefarm.getDevice params, (err, data) ->
        assertError(err, 'NotFoundException')
        matchError(err, 'No device was found for arn arn:aws:devicefarm:us-west-2::device:00000000000000000000000000000000')
        noData(data)
        done()

  describe 'HiveTaxi.DirectConnect', ->
    it 'makes a request', (done) ->
      directconnect.describeConnections (err, data) ->
        noError(err)
        expect(Array.isArray(data.connections)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        connectionId: 'dxcon-fakeconn'
      directconnect.confirmConnection params, (err, data) ->
        assertError(err, 'DirectConnectClientException')
        matchError(err, 'ConfirmConnection failed. dxcon-fakeconn doesn\'t exist.')
        noData(data)
        done()

  describe 'HiveTaxi.DynamoDB', ->
    it 'writes and reads from a table', (done) ->
      key = uniqueName('test')
      dynamodb.putItem {Item: {id: {S: key}, data: {S: 'ƒoo'}}}, (err, data) ->
        noError(err)
        dynamodb.getItem {Key: {id: {S: key}}}, (err, data) ->
          noError(err)
          expect(data.Item.data.S).to.equal('ƒoo')
          dynamodb.deleteItem({Key: {id: {S: key}}}).send(done)

    it 'handles errors', (done) ->
      dynamodb.describeTable {TableName: 'fake-table'}, (err, data) ->
        noData(data)
        assertError(err, 'ResourceNotFoundException')
        matchError(err, 'Requested resource not found: Table: fake-table not found')
        done()

  describe 'HiveTaxi.DynamoDBStreams', ->
    it 'makes a request', (done) ->
      dynamodbstreams.listStreams (err, data) ->
        noError(err)
        expect(Array.isArray(data.Streams)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      params =
        StreamArn: 'fake-stream'
      dynamodbstreams.describeStream params, (err, data) ->
        assertError(err, 'ValidationException')
        matchError(err, 'Invalid StreamArn')
        noData(data)
        done()

  describe 'HiveTaxi.EC2', ->
    it 'makes a request', (done) ->
      ec2.describeInstances (err, data) ->
        noError(err)
        expect(Array.isArray(data.Reservations)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      ec2.deleteVolume {VolumeId: 'vol-12345678'}, (err, data) ->
        noData(data)
        assertError(err, 'InvalidVolume.NotFound')
        matchError(err, 'The volume \'vol-12345678\' does not exist')
        done()

  describe 'HiveTaxi.ECR', ->
    it 'makes a request', (done) ->
      ecr.describeRepositories (err, data) ->
        noError(err)
        expect(Array.isArray(data.repositories)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      ecr.listImages {repositoryName: 'fake-name'}, (err, data) ->
        noData(data)
        assertError(err, 'RepositoryNotFoundException')
        done()

  describe 'HiveTaxi.ECS', ->
    it 'makes a request', (done) ->
      ecs.listClusters {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.clusterArns)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      ecs.stopTask {task: 'xxxxxxxxxxx-xxxxxxxxxxxx-xxxxxxxxxxx'}, (err, data) ->
        noData(data)
        done()

  describe 'HiveTaxi.ElasticTranscoder', ->
    it 'makes a request', (done) ->
      elastictranscoder.listPipelines (err, data) ->
        noError(err)
        expect(Array.isArray(data.Pipelines)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      elastictranscoder.readJob {Id: '3333333333333-abcde3'}, (err, data) ->
        noData(data)
        assertError(err, 'ResourceNotFoundException')
        done()

  describe 'HiveTaxi.ElastiCache', ->
    it 'makes a request', (done) ->
      elasticache.describeSnapshots {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.Snapshots)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      elasticache.listAllowedNodeTypeModifications {}, (err, data) ->
        assertError(err, 'InvalidParameterCombination')
        noData(data)
        done()

  describe 'HiveTaxi.ElasticBeanstalk', ->
    it 'makes a request', (done) ->
      elasticbeanstalk.listAvailableSolutionStacks {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.SolutionStacks)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      elasticbeanstalk.describeEnvironmentHealth {}, (err, data) ->
        assertError(err, 'MissingParameter')
        noData(data)
        done()

  describe 'HiveTaxi.ELB', ->
    it 'makes a request', (done) ->
      elb.describeLoadBalancers {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.LoadBalancerDescriptions)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      elb.describeTags {LoadBalancerNames: ['fake-name']}, (err, data) ->
        assertError(err, 'LoadBalancerNotFound')
        noData(data)
        done()

  describe 'HiveTaxi.EMR', ->
    it 'makes a request', (done) ->
      emr.listClusters {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.Clusters)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      emr.describeCluster {ClusterId: 'fake-id'}, (err, data) ->
        assertError(err, 'InvalidRequestException')
        noData(data)
        done()

  describe 'HiveTaxi.Firehose', ->
    it 'makes a request', (done) ->
      firehose.listDeliveryStreams {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.DeliveryStreamNames)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      firehose.describeDeliveryStream {DeliveryStreamName: 'fake-name'}, (err, data) ->
        assertError(err, 'ResourceNotFoundException')
        noData(data)
        done()

  describe 'HiveTaxi.GameLift', ->
    it 'makes a request', (done) ->
      gamelift.listBuilds {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.Builds)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      gamelift.describeAlias {AliasId: 'fake-id'}, (err, data) ->
        assertError(err, 'InvalidRequestException')
        noData(data)
        done()

  describe 'HiveTaxi.Inspector', ->
    it 'makes a request', (done) ->
      inspector.listRulesPackages (err, data) ->
        noError(err)
        expect(Array.isArray(data.rulesPackageArns)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      inspector.stopAssessmentRun {assessmentRunArn: 'fake-arn'}, (err, data) ->
        noData(data)
        assertError(err, 'InvalidInputException')
        done()

  describe 'HiveTaxi.Iot', ->
    it 'makes a request', (done) ->
      iot.listPolicies (err, data) ->
        noError(err)
        expect(Array.isArray(data.policies)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      iot.describeThing {thingName: 'fake-name'}, (err, data) ->
        noData(data)
        assertError(err, 'ResourceNotFoundException')
        done()

  describe 'HiveTaxi.Kinesis', ->
    it 'makes a request', (done) ->
      kinesis.listStreams (err, data) ->
        noError(err)
        expect(Array.isArray(data.StreamNames)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      kinesis.describeStream {StreamName: 'fake-stream'}, (err, data) ->
        noData(data)
        assertError(err, 'ResourceNotFoundException')
        matchError(err, 'Stream fake-stream under account')
        done()

  describe 'HiveTaxi.KMS', ->
    it 'lists keys', (done) ->
      kms.listKeys (err, data) ->
        noError(err)
        expect(Array.isArray(data.Keys)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      kms.createAlias {AliasName: 'fake-alias', TargetKeyId: 'non-existent'}, (err, data) ->
        noData(data)
        assertError(err, 'ValidationException')
        done()

  describe 'HiveTaxi.Lambda', ->
    it 'makes a request', (done) ->
      lambda.listFunctions (err, data) ->
        noError(err)
        expect(Array.isArray(data.Functions)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      lambda.invoke {FunctionName: 'fake-function'}, (err, data) ->
        noData(data)
        assertError(err, 'ResourceNotFoundException')
        matchError(err, 'function not found')
        done()

  describe 'HiveTaxi.MobileAnalytics', ->
    it 'makes a request', (done) ->
      params =
        'events': [ {
          'eventType': '_session.start'
          'timestamp': '2015-03-19T17:32:40.577Z'
          'session':
            'id': '715fc007-8c32-1e50-0cf2-c45311393281'
          'startTimestamp': '2015-03-19T17:32:40.560Z'
          'version': 'v2.0'
          'attributes': {}
          'metrics': {}
        } ]
        'clientContext': '{"client":{"client_id":"b4a5edf7-fbd4-6e8f-e0ba-8a5632c76191"},"env":{"platform":""},"services":{"mobile_analytics":{"app_id":"f94b9f4fd5004f94a31b66187a227610","sdk_name":"hivetaxi-sdk-mobile-analytics-js","sdk_version":"0.9.0"}},"custom":{}}'
      mobileanalytics.putEvents params, (err, data) ->
        noError(err)
        done()

    it 'handles errors', (done) ->
      params =
        'events': [ {
          'eventType': 'test'
          'timestamp': 'test'
        } ]
        'clientContext': 'test'
      mobileanalytics.putEvents params, (err, data) ->
        noData(data)
        assertError(err, 'BadRequestException')
        matchError(err, 'Client context is malformed or missing')
        done()

  describe 'HiveTaxi.MachineLearning', ->
    it 'makes a request', (done) ->
      machinelearning.describeMLModels (err, data) ->
        noError(err)
        expect(Array.isArray(data.Results)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      machinelearning.getBatchPrediction {BatchPredictionId: 'fake-id'}, (err, data) ->
        noData(data)
        assertError(err, 'ResourceNotFoundException')
        matchError(err, 'No BatchPrediction with id fake-id exists')
        done()

  describe 'HiveTaxi.OpsWorks', ->
    it 'makes a request', (done) ->
      opsworks.describeStacks (err, data) ->
        noError(err)
        expect(Array.isArray(data.Stacks)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      opsworks.describeLayers {StackId: 'fake-id'}, (err, data) ->
        noData(data)
        assertError(err, 'ResourceNotFoundException')
        matchError(err, 'Unable to find stack with ID fake-id')
        done()

  describe 'HiveTaxi.RDS', ->
    it 'makes a request', (done) ->
      rds.describeCertificates (err, data) ->
        noError(err)
        expect(Array.isArray(data.Certificates)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      rds.listTagsForResource {ResourceName: 'fake-name'}, (err, data) ->
        noData(data)
        assertError(err, 'InvalidParameterValue')
        done()

  describe 'HiveTaxi.Redshift', ->
    it 'makes a request', (done) ->
      redshift.describeClusters (err, data) ->
        noError(err)
        expect(Array.isArray(data.Clusters)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      redshift.describeResize {ClusterIdentifier: 'fake-id'}, (err, data) ->
        noData(data)
        assertError(err, 'ClusterNotFound')
        done()

  describe 'HiveTaxi.Route53', ->
    it 'makes a request', (done) ->
      route53.listHostedZones (err, data) ->
        noError(err)
        expect(Array.isArray(data.HostedZones)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      route53.createHostedZone {Name: 'fake-name', 'CallerReference': 'fake-ref'}, (err, data) ->
        noData(data)
        assertError(err, 'InvalidDomainName')
        done()

  describe 'HiveTaxi.Route53Domains', ->
    it 'makes a request', (done) ->
      route53domains.listDomains (err, data) ->
        noError(err)
        expect(Array.isArray(data.Domains)).to.equal(true)
        done()

    it 'handles errors', (done) ->
      route53domains.registerDomain {DomainName: 'example.com', DurationInYears: '1', AdminContact: {}, RegistrantContact: {}, TechContact: {}}, (err, data) ->
        noData(data)
        assertError(err, 'InvalidInput')
        done()

  describe 'HiveTaxi.S3', ->
    testWrite = (done, body, compareFn, svc) ->
      svc = svc || s3
      key = uniqueName('test')
      s3.putObject {Key: key, Body: body}, (err, data) ->
        noError(err)
        s3.getObject {Key: key}, (err, data) ->
          noError(err)
          if compareFn
            compareFn(data)
          else
            expect(data.Body.toString()).to.equal(body)
          s3.deleteObject(Key: key).send(done)

    it 'GETs and PUTs objects to a bucket', (done) ->
      testWrite done, 'ƒoo'

    it 'GETs and PUTs objects to a bucket with signature version 4', (done) ->
      svc = new HiveTaxi.S3(HiveTaxi.util.merge({signatureVersion: 'v1'}, config.s3))
      testWrite done, 'ƒoo', null, svc

    it 'writes typed array data', (done) ->
      testWrite done, new Uint8Array([2, 4, 8]), (data) ->
        expect(data.Body[0]).to.equal(2)
        expect(data.Body[1]).to.equal(4)
        expect(data.Body[2]).to.equal(8)

    it 'writes blobs', (done) ->
      testWrite done, new Blob(['a', 'b', 'c']), (data) ->
        expect(data.Body[0]).to.equal(97)
        expect(data.Body[1]).to.equal(98)
        expect(data.Body[2]).to.equal(99)

    it 'writes with charset', (done) ->
      key = uniqueName('test')
      body = 'body string'
      s3.putObject {Key: key, Body: body, ContentType: 'text/html'}, (err, data) ->
        noError(err)
        s3.deleteObject(Key: key).send ->
          s3.putObject {Key: key, Body: body, ContentType: 'text/html; charset=utf-8'}, (err, data) ->
            noError(err)
            s3.deleteObject(Key: key).send(done)

    describe 'upload()', ->
      it 'supports blobs using upload()', (done) ->
        key = uniqueName('test')
        size = 100
        u = s3.upload(Key: key, Body: new Blob([new Uint8Array(size)]))
        u.send (err, data) ->
          expect(err).not.to.exist
          expect(typeof data.ETag).to.equal('string')
          expect(typeof data.Location).to.equal('string')
          done()

    describe 'progress events', ->
      it 'emits http(Upload|Download)Progress events (no phantomjs)', (done) ->
        data = []
        progress = []
        key = uniqueName('test')
        body = new Blob([new Uint8Array(512 * 1024)])
        req = s3.putObject(Key: key, Body: body)
        req.on 'httpUploadProgress', (p) -> progress.push(p)
        req.send (err, data) ->
          noError(err)
          expect(progress.length > 1).to.equal(true)
          expect(progress[0].total).to.equal(body.size)
          expect(progress[0].loaded > 10).to.equal(true)

          progress = []
          req = s3.getObject(Key: key)
          req.on 'httpDownloadProgress', (p) -> progress.push(p)
          req.send (err, data) ->
            noError(err)
            expect(progress.length > 1).to.equal(true)
            expect(progress[0].total).to.equal(body.size)
            expect(progress[0].loaded > 10).to.equal(true)
            s3.deleteObject(Key: key).send(done)

  describe 'HiveTaxi.SES', ->
    it 'makes a request', (done) ->
      ses.listIdentities {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.Identities)).to.equal(true)
        done()
    it 'handles errors', (done) ->
      params =
        RuleSetName: 'fake-name'
        RuleName: 'fake-name'
      ses.describeReceiptRule params, (err, data) ->
        assertError(err, 'RuleSetDoesNotExist')
        noData(data)
        done()

  describe 'HiveTaxi.SNS', ->
    it 'creates and deletes topics', (done) ->
      sns.createTopic {Name: uniqueName('hivetaxi-sdk-js')}, (err, data) ->
        noError(err)
        arn = data.TopicArn
        sns = new HiveTaxi.SNS(sns.config)
        sns.config.params = TopicArn: arn
        sns.listTopics (err, data) ->
          expect(data.Topics.filter((o) -> o.TopicArn == arn)).not.to.equal(null)
          sns.deleteTopic(done)

  describe 'HiveTaxi.SQS', ->
    it 'posts and receives messages on a queue', (done) ->
      name = uniqueName('hivetaxi-sdk-js')
      msg = 'ƒoo'
      sqs.createQueue {QueueName: name}, (err, data) ->
        url = data.QueueUrl
        sqs = new HiveTaxi.SQS(sqs.config)
        sqs.config.params = QueueUrl: url
        eventually ((err) -> err == null),
          ((cb) -> sqs.getQueueUrl({QueueName: name}, cb)), ->
            sqs.sendMessage {MessageBody:msg}, (err, data) ->
              noError(err)
              eventually ((err, data) -> data.Messages[0].Body == msg),
                ((cb) -> sqs.receiveMessage(cb)), (err, data) ->
                  noError(err)
                  expect(data.Messages[0].MD5OfBody).to.equal(HiveTaxi.util.crypto.md5(msg, 'hex'))
                  sqs.deleteQueue(done)

  describe 'HiveTaxi.SSM', ->
    it 'makes a request', (done) ->
      ssm.listCommands {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.Commands)).to.equal(true)
        done()
    it 'handles errors', (done) ->
      params =
        Name: 'fake-name'
      ssm.describeDocument params, (err, data) ->
        assertError(err, 'InvalidDocument')
        noData(data)
        done()

    describe 'HiveTaxi.StorageGateway', ->
    it 'makes a request', (done) ->
      storagegateway.listGateways {}, (err, data) ->
        noError(err)
        expect(Array.isArray(data.Gateways)).to.equal(true)
        done()
    it 'handles errors', (done) ->
      params =
        GatewayARN: 'fake-arn'
      storagegateway.describeGatewayInformation params, (err, data) ->
        assertError(err, 'ValidationException')
        noData(data)
        done()

  describe 'HiveTaxi.STS', ->
    it 'gets a session token', (done) ->
      sts.getSessionToken (err, data) ->
        noError(err)
        expect(data.Credentials.AccessKeyId).not.to.equal('')
        done()

  describe 'HiveTaxi.WAF', ->
    it 'makes a request', (done) ->
      params =
        Limit: 20
      waf.listRules params, (err, data) ->
        noError(err)
        expect(Array.isArray(data.Rules)).to.equal(true)
        done()
    it 'handles errors', (done) ->
      params =
        Name: 'fake-name'
        ChangeToken: 'fake-token'
      waf.createSqlInjectionMatchSet params, (err, data) ->
        assertError(err, 'WAFStaleDataException')
        noData(data)
        done()

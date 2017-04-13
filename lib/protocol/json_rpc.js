var util = require('../util');
var Rest = require('./rest');
var Json = require('./json');
var JsonBuilder = require('../json/builder');
var JsonParser = require('../json/parser');

function populateBody(req) {
    var builder = new JsonBuilder();
    var operation = req.service.api.operations[req.operation];
    var input = operation.input;
    var inputShape = input;
    var params = {};
    var defaultTarget = (req.service.api.targetPrefix + '.' + operation.name);

    var json_body = {
        method: operation.httpTarget || defaultTarget,
        version: req.service.api.apiVersion
    };

    if (input.payload) {
        var payloadShape = input.members[input.payload];
        if (req.params[input.payload] === undefined) return;

        if (payloadShape.type === 'structure') {
            inputShape = payloadShape;
            params = req.params[input.payload];
        } else { // non-JSON payload
        }
    } else {
        params = req.params;
    }

    if (params.hasOwnProperty('requestId') && params.requestId) {
        json_body.id = params.requestId;
        delete params.requestId;
    }

    json_body.params = JSON.parse(builder.build(params, inputShape));
    req.httpRequest.body = JSON.stringify(json_body);
}

function buildRequest(req) {
    var operation = req.service.api.operations[req.operation];
    // var defaultTarget = (req.service.api.targetPrefix + '.' + operation.name);

    Rest.buildRequest(req);
    req.httpRequest.method = 'POST';
    req.httpRequest.headers['Content-Type'] = 'application/json';
    // req.httpRequest.headers['X-Hive-Target'] = operation.httpTarget || defaultTarget;
    populateBody(req);
}

function extractError(resp) {
    var error = {};
    var httpResponse = resp.httpResponse;

    error.code = httpResponse.headers['x-hive-errortype'] || 'UnknownError';
    if (typeof error.code === 'string') {
        error.code = error.code.split(':')[0];
    }

    if (httpResponse.body.length > 0) {
        var r = JSON.parse(httpResponse.body.toString());
        if (r.error) {
            error.code = (r.error.code).toString().split('#').pop();
        }
        if (error.code === 'RequestEntityTooLarge') {
            error.message = 'Request body must be less than 1 MB';
        } else {
            error.message = (r.error.message || r.error.Message || null);
        }
        if (r.id) {
            error.requestId = r.id;
        }
    } else {
        error.statusCode = httpResponse.statusCode;
        error.message = httpResponse.statusCode.toString();
    }

    resp.error = util.error(new Error(), error);
}

function extractData(resp) {
    Rest.extractData(resp);

    var json = JSON.parse(resp.httpResponse.body.toString() || '{}');
    if (!util.isEmpty(json) && json.hasOwnProperty('error')) {
        extractError(resp);
        return;
    }

    var req = resp.request;
    var rules = req.service.api.operations[req.operation].output || {};
    if (rules.payload) {
        var payloadMember = rules.members[rules.payload];
        var body = resp.httpResponse.body;
        if (payloadMember.isStreaming) {
            resp.data[rules.payload] = body;
        } else if (payloadMember.type === 'structure' || payloadMember.type === 'list') {
            var parser = new JsonParser();
            resp.data[rules.payload] = parser.parse(body, payloadMember);
        } else {
            resp.data[rules.payload] = body.toString();
        }
    } else {
        var data = resp.data;
        Json.extractData(resp);
        if (!util.isEmpty(data)) {
            resp.data = util.merge(data, resp.data);
        }
    }
    if (!util.isEmpty(resp.data) && resp.data.hasOwnProperty('result')) {
        resp.data = resp.data.result;
    }
}

module.exports = {
    buildRequest: buildRequest,
    extractError: extractError,
    extractData: extractData
};

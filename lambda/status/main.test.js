const retrieveStatus = require("./main");
var AWS = require('aws-sdk-mock');
const ProcessStatusMessage = require('./constants').ProcessStatusMessage;

describe("When asked for a status given a UUID, and the payload is not yet being processed", () => {
    let result;

    beforeAll(async () => {
        AWS.mock('DynamoDB.DocumentClient', 'get', function (params, callback){
            callback(null, {Item: {PROCESS_STATUS: ProcessStatusMessage.ACCEPTED}});
          });

        let event = {pathParameters: {uuid: "7"}};
        result = await retrieveStatus.handler(event);
    });

    test("It should return a successful status code", async () => {
        expect(result.statusCode).toBe(200);
    });

    test("It should return ACCEPTED status", async () => {
        expect(result.body).toBe(`{"process_status":"${ProcessStatusMessage.ACCEPTED}"}`);
    });

    afterAll(() => {
        AWS.restore('DynamoDB.DocumentClient');
    });
});

describe("When asked for a status given a UUID, and the payload is being processed", () => {
    let result;

    beforeAll(async () => {
        AWS.mock('DynamoDB.DocumentClient', 'get', function (params, callback){
            callback(null, {Item: {PROCESS_STATUS: ProcessStatusMessage.PROCESSING}});
          });

        let event = {pathParameters: {uuid: "7"}};
        result = await retrieveStatus.handler(event);
    });

    test("It should return a successful status code", async () => {
        expect(result.statusCode).toBe(200);
    });

    test("It should return PROCESSING status", async () => {
        expect(result.body).toBe(`{"process_status":"${ProcessStatusMessage.PROCESSING}"}`);
    });

    afterAll(() => {
        AWS.restore('DynamoDB.DocumentClient');
    });
});

describe("When asked for a status given a UUID, and the payload has been processed", () => {
    let result;

    beforeAll(async () => {
        AWS.mock('DynamoDB.DocumentClient', 'get', function (params, callback){
            callback(null, {Item: {PROCESS_STATUS: ProcessStatusMessage.COMPLETED}});
          });

        let event = {pathParameters: {uuid: "7"}};
        result = await retrieveStatus.handler(event);
    });

    test("It should return a successful status code", async () => {
        expect(result.statusCode).toBe(200);
    });

    test("It should return COMPLETED status", async () => {
        expect(result.body).toBe(`{"process_status":"${ProcessStatusMessage.COMPLETED}"}`);
    });

    afterAll(() => {
        AWS.restore('DynamoDB.DocumentClient');
    });
});

describe("When asked for a status given a UUID, and the there is an error when searching the db", () => {
    let result;

    beforeAll(async () => {
        AWS.mock('DynamoDB.DocumentClient', 'get', function (params, callback){
            callback(null, Promise.reject('Oops!'));
        });

        let event = {pathParameters: {uuid: "7"}};
        result = await retrieveStatus.handler(event);
    });

    test("It should return a not found status code", async () => {
        expect(result.statusCode).toBe(404);
    });

    afterAll(() => {
        AWS.restore('DynamoDB.DocumentClient');
    });
});
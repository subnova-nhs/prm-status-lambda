const AWS = require('aws-sdk');
AWS.config.update({region: 'eu-west-2'});

class MigrationEventStateMachine {
    constructor(client) {
        this.uuid = undefined;
        this.status = undefined;
        this.client = client;
    }

    async get(uuid) {
        try {
            let result = await this.client.get(uuid);
            this.uuid = uuid;
            this.status = result.Item.PROCESS_STATUS;
        } catch (err) {
            this.status = 'NOT FOUND';
        }

        return this;
    }

    get currentStatus() {
        return this.status;
    }
}

exports.main = async function (dbClient, uuid) {
    var event = new MigrationEventStateMachine(new ProcessStatusWrapper(dbClient));
    return event.get(uuid);
};

class ProcessStatusWrapper {
    constructor(dbClient) {
        this.dbClient = dbClient;
    }

    async get(key) {
        let result = await this.dbClient
            .get({
                TableName: process.env.TABLE_NAME,
                Key: {
                    PROCESS_ID: key
                }
            })
            .promise();
        
        return result;
    }
}

exports.handler = async (event, context) => {
    const uuid = event.pathParameters.uuid;
    const client = new AWS.DynamoDB.DocumentClient();
    // call the business logic
    const result = await module.exports.main(client, uuid);
    // handle converting back to AWS
    return {
        statusCode: result.currentStatus === "NOT FOUND" ? 404 : 200,
        body: JSON.stringify({
            uuid: result.correlationId,
            process_status: result.currentStatus,
        }),
        isBase64Encoded: false
    };
};


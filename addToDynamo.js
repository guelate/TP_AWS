const AWS = require('aws-sdk');

exports.handler = async (event) => {
  const dynamodb = new AWS.DynamoDB.DocumentClient();
  const jobType = event.job_type;
  const content = event.content;

  const params = {
    TableName: 'job_table',
    Item: {
      id: 'unique-id',
      job_type: jobType,
      content: content,
      processed: false
    }
  };

  await dynamodb.put(params).promise();

  return {
    statusCode: 200,
    body: 'Job processed successfully'
  };
};
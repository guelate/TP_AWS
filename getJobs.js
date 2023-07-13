const AWS = require('aws-sdk');

exports.handler = async (event) => {
  const dynamodb = new AWS.DynamoDB.DocumentClient();
  const tableName = 'job_table';

  try {
    const params = {
      TableName: tableName,
      FilterExpression: 'attribute_exists(processed)',
      ProjectionExpression: 'id, job_type, content, processed'
    };

    const result = await dynamodb.scan(params).promise();

    return {
      statusCode: 200,
      body: JSON.stringify(result.Items)
    };
  } catch (error) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};
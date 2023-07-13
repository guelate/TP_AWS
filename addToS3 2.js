const AWS = require('aws-sdk');

exports.handler = async (event) => {
  const s3 = new AWS.S3();
  const content = event.content;

  const params = {
    Body: content,
    Bucket: 'mon-bucket',
    Key: 'mon-fichier.txt'
  };

  await s3.putObject(params).promise();

  return {
    statusCode: 200,
    body: 'Job processed successfully'
  };
};
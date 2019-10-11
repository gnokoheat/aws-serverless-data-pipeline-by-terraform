const AWS = require("aws-sdk");

exports.handler = (event, context, callback) => {
  if (event.httpMethod === "POST") {
    const firehose = new AWS.Firehose();
    const records = JSON.parse(event.body);
    firehose.putRecord({
      DeliveryStreamName: "${firehose}",
      Record: {
        Data: JSON.stringify(records) + "\n"
      },
    }).promise().then((res) => {
      callback(null, {
        statusCode: 200,
        body: JSON.stringify({ output: res }),
      });
    }).catch((e) => {
      callback(null, {
        statusCode: 500,
        body: JSON.stringify({ error: e }),
      });
    });
  } else {
     callback(null, {
       statusCode: 404,
     });
  }
}
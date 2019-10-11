data "template_file" "lambda_tpl" {
  template = "${file("${path.module}/index.js.tpl")}"
  vars = {
        firehose = "${aws_kinesis_firehose_delivery_stream.data_stream.name}"
    }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "lambda_function.zip"

  source {
    content  = "${data.template_file.lambda_tpl.rendered}"
    filename = "index.js"
  }
}

resource "aws_lambda_function" "lambda" {
  filename         = "lambda_function.zip"
  function_name    = "${var.service_name}-${var.workspace}"
  role             = "${aws_iam_role.lambda.arn}"
  handler          = "index.handler"
  source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
  runtime          = "nodejs10.x"
}

data "aws_iam_policy_document" "assume_by_lambda" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.service_name}-lambdaRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_by_lambda.json}"
}

data "aws_iam_policy_document" "lambda" {
  statement {
    sid    = ""
    effect = "Allow"

    actions = [
        "logs:CreateLogGroup"
    ]

    resources = [
        "arn:aws:logs:${var.region}:${var.aws_account_id}:*"
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    actions = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
    ]

    resources = [
        "arn:aws:logs:${var.region}:${var.aws_account_id}:log-group:/aws/lambda/${aws_lambda_function.lambda.function_name}:*"
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"

    actions = [
        "kinesis:DescribeStreamSummary",
        "kinesis:DescribeStream",
        "kinesis:ListStreams",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kinesis:ListTagsForStream"
    ]

    resources = ["*"]
  }

    statement {
    sid    = ""
    effect = "Allow"

    actions = [
        "firehose:DeleteDeliveryStream",
        "firehose:PutRecord",
        "firehose:PutRecordBatch",
        "firehose:UpdateDestination"
    ]

    resources = [
        "arn:aws:firehose:${var.region}:${var.aws_account_id}:*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda" {
  role   = "${aws_iam_role.lambda.name}"
  policy = "${data.aws_iam_policy_document.lambda.json}"
}
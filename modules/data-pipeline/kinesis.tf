resource "aws_s3_bucket" "bucket" {
  bucket = "${var.service_name}-${var.workspace}-data-pipeline"
  acl    = "private"
}

resource "aws_iam_role" "firehose" {
  name = "${var.service_name}-firehose_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${var.aws_account_id}"
        }
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "firehose" {
  statement {
    sid    = ""
    effect = "Allow"

    actions = [
        "glue:GetTable",
        "glue:GetTableVersion",
        "glue:GetTableVersions"
    ]
    resources = ["*"]
  }

  statement {
    sid    = ""
    effect = "Allow"

    actions = [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.service_name}-${var.workspace}-data-pipeline",
      "arn:aws:s3:::${var.service_name}-${var.workspace}-data-pipeline/*",
      "arn:aws:s3:::%FIREHOSE_BUCKET_NAME%",
      "arn:aws:s3:::%FIREHOSE_BUCKET_NAME%/*"
    ]
  }

    statement {
    sid    = ""
    effect = "Allow"

    actions = [
        "lambda:InvokeFunction",
        "lambda:GetFunctionConfiguration"
    ]
    resources = [
        "arn:aws:lambda:${var.region}:${var.aws_account_id}:function:%FIREHOSE_DEFAULT_FUNCTION%:%FIREHOSE_DEFAULT_VERSION%"
    ]
  }

    statement {
    sid    = ""
    effect = "Allow"

    actions = [
        "kinesis:DescribeStream",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords"
    ]
    resources = ["arn:aws:kinesis:${var.region}:${var.aws_account_id}:stream/%FIREHOSE_STREAM_NAME%"]
  }

    statement {
    sid    = ""
    effect = "Allow"

    actions = [
        "kms:Decrypt"
    ]
    resources = ["arn:aws:kms:${var.region}:${var.aws_account_id}:key/%SSE_KEY_ID%"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"

      values = [
        "kinesis.%REGION_NAME%.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:kinesis:arn"

      values = [
        "arn:aws:kinesis:%REGION_NAME%:${var.aws_account_id}:stream/%FIREHOSE_STREAM_NAME%"
      ]
    }
  }
}

resource "aws_iam_role_policy" "firehose" {
  role   = "${aws_iam_role.firehose.name}"
  policy = "${data.aws_iam_policy_document.firehose.json}"
}

resource "aws_kinesis_firehose_delivery_stream" "data_stream" {
  name        = "${var.service_name}-firehose-data-stream"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = "${aws_iam_role.firehose.arn}"
    bucket_arn = "${aws_s3_bucket.bucket.arn}"
    compression_format = "GZIP"
    buffer_size        = "${var.s3_buffer_size}"
    buffer_interval    = "${var.s3_buffer_interval}"
    prefix = "log/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
    error_output_prefix = "error/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}"
  }
}
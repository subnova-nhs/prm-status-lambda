locals {
  function_name = "ehr-translate-status-${var.environment}"
}

resource "aws_s3_bucket" "lambda" {
  bucket = "prm-${data.aws_caller_identity.current.account_id}-status-lambda-${lower(var.environment)}"
  acl    = "private"
}

resource "aws_s3_bucket_object" "lambda" {
  bucket = "${aws_s3_bucket.lambda.bucket}"
  key    = "lambda.zip"
  source = "${path.module}/${var.lambda_zip}"
  etag   = "${md5(file("${path.module}/${var.lambda_zip}"))}"
}

resource "aws_lambda_function" "lambda" {
  s3_bucket        = "${aws_s3_bucket_object.lambda.bucket}"
  s3_key           = "${aws_s3_bucket_object.lambda.key}"
  function_name    = "${local.function_name}"
  handler          = "main.handler"
  role             = "${aws_iam_role.lambda.arn}"
  description      = "EHR translate status EHR API handler for ${var.environment}"
  memory_size      = 128
  timeout          = 20
  runtime          = "nodejs8.10"
  source_code_hash = "${base64sha256(file("${path.module}/${var.lambda_zip}"))}"

  environment {
    variables {
      TABLE_NAME = "PROCESS_STORAGE_${upper(var.environment)}"
    }
  }

  tags {
    Name          = "ehr-translate-status-${var.environment}"
    Enviroronment = "${var.environment}"
    Component     = "ehr-extract"
  }
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name = "ehr-translate-status-${var.environment}"

  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume.json}"
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "dynamodb:*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "lambda" {
  name = "ehr-translate-status-${var.environment}"
  role = "${aws_iam_role.lambda.id}"

  policy = "${data.aws_iam_policy_document.lambda_policy.json}"
}

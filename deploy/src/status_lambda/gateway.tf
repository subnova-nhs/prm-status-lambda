# API Gateway

data "aws_caller_identity" "current" {}

resource "aws_lambda_permission" "allow_invoke_from_api_gw" {
  depends_on = [ "aws_lambda_function.lambda"]

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${local.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${data.aws_api_gateway_rest_api.api_gw_endpoint.id}/*/*/*"
}

data "aws_api_gateway_rest_api" "api_gw_endpoint" {
  name = "ehr-translate-${var.environment}"
}

resource "aws_api_gateway_resource" "status_resource" {
  rest_api_id = "${data.aws_api_gateway_rest_api.api_gw_endpoint.id}"
  parent_id   = "${data.aws_api_gateway_rest_api.api_gw_endpoint.root_resource_id}"
  path_part   = "status"
}

resource "aws_api_gateway_resource" "status_uuid_resource" {
  rest_api_id = "${data.aws_api_gateway_rest_api.api_gw_endpoint.id}"
  parent_id   = "${aws_api_gateway_resource.status_resource.id}"
  path_part   = "{uuid}"
}

resource "aws_api_gateway_method" "status_uuid_get_method" {
  rest_api_id   = "${data.aws_api_gateway_rest_api.api_gw_endpoint.id}"
  resource_id   = "${aws_api_gateway_resource.status_uuid_resource.id}"
  http_method   = "GET"
  authorization = "NONE"

  request_parameters {
    "method.request.path.uuid" = true
  }
}

resource "aws_api_gateway_integration" "api_gw_integration" {
  rest_api_id = "${data.aws_api_gateway_rest_api.api_gw_endpoint.id}"
  resource_id = "${aws_api_gateway_resource.status_uuid_resource.id}"
  http_method = "${aws_api_gateway_method.status_uuid_get_method.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambda.invoke_arn}"
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name                     = "${var.service_name}-API"
  description              = "API for ${var.service_name}"
  minimum_compression_size = 0
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api.root_resource_id}"
  path_part   = "${var.service_name}"
}

# Requests mapping
resource "aws_api_gateway_method" "any_method" {
  rest_api_id   = "${aws_api_gateway_rest_api.api.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "${var.apigw_method}"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "request_integration" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_method.any_method.resource_id}"
  http_method = "${aws_api_gateway_method.any_method.http_method}"
  type        = "AWS_PROXY"
  uri         = "${aws_lambda_function.lambda.invoke_arn}"
  integration_http_method = "${var.apigw_method}"
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  resource_id = "${aws_api_gateway_resource.proxy.id}"
  http_method = "${aws_api_gateway_method.any_method.http_method}"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

# Deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.api.id}"
  stage_name  = "${var.workspace}"

  depends_on = [
    "aws_api_gateway_integration.request_integration"
  ]
}

# API Permissions
resource "aws_lambda_permission" "allow_api_gateway" {
  function_name = "${aws_lambda_function.lambda.arn}"
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/${var.service_name}"

  depends_on = [
    "aws_api_gateway_rest_api.api",
    "aws_api_gateway_resource.proxy",
  ]
}

resource "aws_api_gateway_api_key" "api_key" {
  name = "${var.service_name}-Key"
}

resource "aws_api_gateway_usage_plan" "api_usage_plan" {
  name = "usage_${var.service_name}-API"

  api_stages {
    api_id = "${aws_api_gateway_rest_api.api.id}"
    stage  = "${aws_api_gateway_deployment.deployment.stage_name}"
  }
}

resource "aws_api_gateway_usage_plan_key" "api_usage_plan_key" {
  key_id        = "${aws_api_gateway_api_key.api_key.id}"
  key_type      = "API_KEY"
  usage_plan_id = "${aws_api_gateway_usage_plan.api_usage_plan.id}"
}
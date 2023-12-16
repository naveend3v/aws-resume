terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile                  = "aws-resume" # rename your aws cli profile
  region                   = "us-east-1"
}


# DynamoDB Table
resource "aws_dynamodb_table" "visitor_count_ddb" {
  name         = "VisitorsTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "visitors"
    type = "N"
  }

  global_secondary_index {
    name            = "visitors_count"
    hash_key        = "visitors"
    projection_type = "ALL"
    read_capacity   = 1
    write_capacity  = 1
  }

  tags = {
    Name = "Cloud Resume Challenge"
  }
}

# DynamoDB Table Item
resource "aws_dynamodb_table_item" "visitor_count_ddb" {
  table_name = aws_dynamodb_table.visitor_count_ddb.name
  hash_key   = aws_dynamodb_table.visitor_count_ddb.hash_key

  item = <<ITEM
{
  "id": {"S": "visitor_count"},
  "visitors": {"N": "1"}
}
ITEM
}

# Retrieve the current AWS region dynamically
data "aws_region" "current" {}

# Retrieve the current AWS account ID dynamically
data "aws_caller_identity" "current" {}

# create lambda iam role
resource "aws_iam_role" "lambda_role" {
  name               = "aws_resume_lamnbda_role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "lambda.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

# create lambda iam role policy
resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "iam_policy_for_aws_resume_lamnbda_role"
  path        = "/"
  description = "AWS IAM Policy for aws lambda to access dynamodb"
  policy      = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": [
       "dynamodb:BatchGetItem",
       "dynamodb:GetItem",
       "dynamodb:Query",
       "dynamodb:Scan",
       "dynamodb:BatchWriteItem",
       "dynamodb:PutItem",
       "dynamodb:UpdateItem"
     ],
     "Resource": "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*" 
   },
   {
     "Effect": "Allow",
     "Action": [
       "logs:CreateLogStream",
       "logs:PutLogEvents"
     ],
     "Resource": "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*" 
   },
   {
     "Effect": "Allow",
     "Action": "logs:CreateLogGroup",
     "Resource": "*"
   }
 ]
}
EOF
}

# iam role policy attachment to lambda role
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

# Archive the lambda function python code 
data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

# lambda function creation
resource "aws_lambda_function" "terraform_lambda_func" {
  filename      = "${path.module}/lambda/lambda_function.zip"
  function_name = "VistorCounter"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  depends_on    = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
  environment {
    variables = {
      databaseName = "VisitorsTable"
    }
  }

}

# create api gateway
resource "aws_apigatewayv2_api" "visitor_counter_api" {
  name          = "visitor_counter_http_api"
  protocol_type = "HTTP"
  description   = "Visitor counter HTTP API to invoke AWS Lambda function to update & retrieve the visitors count"
  cors_configuration {
      allow_credentials = false
      allow_headers     = []
      allow_methods     = [
          "GET",
          "OPTIONS",
          "POST",
      ]
      allow_origins     = [
          "*",
      ]
      expose_headers    = []
      max_age           = 0
  }

}

# api gateway stage
resource "aws_apigatewayv2_stage" "default" {
  api_id = aws_apigatewayv2_api.visitor_counter_api.id
  name        = "default"
  auto_deploy = true
}

# api gateway integration
resource "aws_apigatewayv2_integration" "visitor_counter_api_integration" {
  api_id = aws_apigatewayv2_api.visitor_counter_api.id
  integration_uri    = aws_lambda_function.terraform_lambda_func.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

# api gateway route
resource "aws_apigatewayv2_route" "any" {
  api_id = aws_apigatewayv2_api.visitor_counter_api.id
  route_key = "ANY /VisitorCounter"
  target    = "integrations/${aws_apigatewayv2_integration.visitor_counter_api_integration.id}"
}

# api gateway lambda invocation permission

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_func.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.visitor_counter_api.execution_arn}/*/*"
}

output "base_url" {
  value = "${aws_apigatewayv2_stage.default.invoke_url}/VisitorCounter"
}
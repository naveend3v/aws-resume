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
  profile                  = "aws-resume"
  region                   = "us-east-2"
  shared_credentials_files = ["C:/Users/Naveen raj/.aws/credentials"]
}

# dynamodb table create
# resource "aws_dynamodb_table" "visitors_dynamodb_table" {
#   name         = "visitors_table"
#   billing_mode = "PAY_PER_REQUEST"
#   hash_key     = "id"
#   range_key    = "visitors"

#   attribute {
#     name = "id"
#     type = "S"
#   }

#   attribute {
#     name = "visitors"
#     type = "N"
#   }

# }

# dynamodb table item
# resource "aws_dynamodb_table_item" "visitors_dynamodb_table" {
#   table_name = aws_dynamodb_table.visitors_dynamodb_table.name
#   hash_key   = aws_dynamodb_table.visitors_dynamodb_table.hash_key
#   range_key = aws_dynamodb_table.visitors_dynamodb_table.range_key

#   item = <<ITEM
# {
#   "id": {"S": "visitor_count"},
#   "visitors": {"N": "1"}
# }
# ITEM
# }

# Retrieve the current AWS region dynamically
data "aws_region" "current" {}

# Retrieve the current AWS account ID dynamically
data "aws_caller_identity" "current" {}

# lambda iam role
resource "aws_iam_role" "lambda_role" {
  name               = "Lambda_Dynamodb_Role"
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


resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "iam_policy_for_aws_dynamodb_role"
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

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

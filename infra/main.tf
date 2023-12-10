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
  profile = "aws-resume"
  region  = "us-east-2"

}

# dynamodb table create
resource "aws_dynamodb_table" "visitors-dynamodb-table" {
  name         = "visitors-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"
  range_key    = "visitors"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "visitors"
    type = "N"
  }

}

# dynamodb table item
resource "aws_dynamodb_table_item" "visitors-dynamodb-table" {
  table_name = aws_dynamodb_table.visitors-dynamodb-table.name
  hash_key   = aws_dynamodb_table.visitors-dynamodb-table.hash_key
  range_key = aws_dynamodb_table.visitors-dynamodb-table.range_key

  item = <<ITEM
{
  "id": {"S": "visitor_count"},
  "visitors": {"N": "1"}
}
ITEM
}


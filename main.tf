terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
name = "lambda_execution_role" 
assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
EOF
}

provider "aws" {
   region = "eu-west-3"
   access_key = "AKIA47JOKG6WJS7P5QAS"
   secret_key = "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"
}

resource "aws_dynamodb_table" "job_table" {
  name           = "job_table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "job_type"
    type = "S"
  }

  attribute {
    name = "content"
    type = "S"
  }
  
   attribute {
    name = "processed"
    type = "N"
  }

  global_secondary_index {
    name               = "job_type_index"
    hash_key           = "job_type"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }

  global_secondary_index {
    name               = "processed_index"
    hash_key           = "processed"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }
  
   global_secondary_index {
    name               = "content_index"
    hash_key           = "content"
    projection_type    = "ALL"
    read_capacity      = 5
    write_capacity     = 5
  }
}

resource "aws_api_gateway_rest_api" "jobs_api" {
  name        = "job-api"
  description = "API for job management"
}

resource "aws_api_gateway_resource" "job_resource" {
  rest_api_id = aws_api_gateway_rest_api.jobs_api.id
  parent_id   = aws_api_gateway_rest_api.jobs_api.root_resource_id
  path_part   = "jobs"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.jobs_api.id
  resource_id   = aws_api_gateway_resource.job_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_lambda_function" "job_lambda" {
  filename      = "./addToS3.zip"
  function_name = "addToS3"
  runtime       = "nodejs14.x"
  handler       = "addToS3.handler"
  role          = aws_iam_role.lambda_execution_role.arn
  source_code_hash = filebase64sha256("./addToS3.zip")

}

resource "aws_lambda_function" "get_jobs_lambda" {
  filename      = "./getJobs.zip"
  function_name = "getJobs"
  runtime       = "nodejs14.x"
  handler       = "getJobs.handler"
  role          = aws_iam_role.lambda_execution_role.arn
  source_code_hash = filebase64sha256("./getJobs.zip") 
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.jobs_api.id
  resource_id             = aws_api_gateway_resource.job_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.job_lambda.invoke_arn
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.jobs_api.id
  resource_id   = aws_api_gateway_resource.job_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.jobs_api.id
  resource_id             = aws_api_gateway_resource.job_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_jobs_lambda.invoke_arn
}

resource "aws_lambda_permission" "job_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.job_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = aws_api_gateway_rest_api.jobs_api.execution_arn
}
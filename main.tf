terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Manter 5.0 ou superior é o ideal
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-execution-role-estudo"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda-permissions-policy-estudo"
  role   = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem"],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.transactions_table.arn
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_ecr_repository" "api_repo" {
  name = "ecr-estudo-api"
}

resource "aws_dynamodb_table" "transactions_table" {
  name         = "tabela-de-transacoes-estudo"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "transaction_id"
  attribute {
    name = "transaction_id"
    type = "S"
  }
}

resource "aws_lambda_function" "transaction_lambda" {
  function_name = "processador-de-transacoes-estudo"
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.api_repo.repository_url}:latest"
  role          = aws_iam_role.lambda_exec_role.arn
  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.transactions_table.name
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "http-teste-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.transaction_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /transaction"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

output "api_endpoint" {
  description = "A URL da nossa API para testes."
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "dynamodb_table_name" {
  description = "O nome da tabela do DynamoDB"
  value       = aws_dynamodb_table.transactions_table.name
}```

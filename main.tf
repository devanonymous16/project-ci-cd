# main.tf

# Configura o Terraform para falar com a nossa AWS Local (LocalStack)
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test" # pode ser qualquer coisa
  secret_key                  = "test" # pode ser qualquer coisa
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # ESSA É A PARTE MAIS IMPORTANTE
  # Aponta todos os serviços para o endpoint do LocalStack
  endpoints {
    apigateway   = "http://localhost:4566"
    dynamodb     = "http://localhost:4566"
    ecr          = "http://localhost:4566"
    iam          = "http://localhost:4566"
    lambda       = "http://localhost:4566"
    s3           = "http://localhost:4566"
  }
}

# 1. Repositório ECR para guardar a imagem Docker da nossa Lambda
resource "aws_ecr_repository" "api_repo" {
  name = "fintech/transaction-api"
}

# 2. Tabela DynamoDB para salvar as transações
resource "aws_dynamodb_table" "transactions_table" {
  name         = "Transactions"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "transaction_id"

  attribute {
    name = "transaction_id"
    type = "S"
  }
}

# 3. IAM Role (Permissões) para a Lambda
# Segue o princípio do menor privilégio
resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 4. Política de permissão para a Lambda escrever no DynamoDB e nos Logs
resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda-policy"
  role = aws_iam_role.lambda_exec_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = ["dynamodb:PutItem"],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.transactions_table.arn
      },
      {
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"],
        Effect   = "Allow",
        Resource = "arn:aws:logs:*:*:*" # Simplificado para o lab
      }
    ]
  })
}

# 5. A Função Lambda, usando a imagem Docker
resource "aws_lambda_function" "transaction_lambda" {
  function_name = "TransactionProcessor"
  role          = aws_iam_role.lambda_exec_role.arn
  package_type  = "Image"
  image_uri     = "${aws_ecr_repository.api_repo.repository_url}:latest"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.transactions_table.name
    }
  }

  depends_on = [aws_iam_role_policy.lambda_policy]
}

# 6. A API Gateway que vai expor nossa Lambda para o mundo
resource "aws_apigatewayv2_api" "http_api" {
  name          = "FintechHttpApi"
  protocol_type = "HTTP"
}

# 7. A Integração entre a rota da API e a Lambda
resource "aws_apigatewayv2_integration" "api_lambda_integration" {
  api_id           = aws_apigatewayv2_api.http_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.transaction_lambda.invoke_arn
}

resource "aws_apigatewayv2_route" "api_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /transaction"
  target    = "integrations/${aws_apigatewayv2_integration.api_lambda_integration.id}"
}

# Permissão para a API Gateway invocar a Lambda
resource "aws_lambda_permission" "api_gateway_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.transaction_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}

# Output para nos dar a URL da API no final
output "api_endpoint" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}
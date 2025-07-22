// Jenkinsfile com Fluxo de Aprovação

pipeline {
    agent any

    environment {
        AWS_ACCOUNT_ID = sh(script: 'aws sts get-caller-identity --query Account --output text', returnStdout: true).trim()
        AWS_REGION = 'us-east-1'
        ECR_REPO_NAME = "fintech/transaction-api"
        ECR_REPO_URL = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO_NAME}"
    }

    stages {
        stage('1. Checkout') {
            steps {
                checkout scm
            }
        }

        // Este stage SÓ RODA se não estivermos na branch 'main'
        stage('2. Terraform Plan (for Pull Request)') {
            when {
                branch 'main'
                comparator 'NOT_EQUALS'
            }
            steps {
                sh 'terraform init -upgrade'
                // Rodamos apenas o 'plan'. O resultado aparecerá no log do Jenkins.
                sh 'terraform plan'
            }
        }

        // Estes stages SÓ RODAM quando o código é mergeado na 'main'
        stage('3. Build and Push Image (to Production)') {
            when {
                branch 'main'
            }
            steps {
                sh "docker build -t ${ECR_REPO_NAME}:latest ."
                sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
                sh "docker tag ${ECR_REPO_NAME}:latest ${ECR_REPO_URL}:latest"
                sh "docker push ${ECR_REPO_URL}:latest"
            }
        }

        stage('4. Terraform Apply (to Production)') {
            when {
                branch 'main'
            }
            steps {
                sh 'terraform init -upgrade'
                // Agora sim, o apply é executado.
                sh 'terraform apply -auto-approve'
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}
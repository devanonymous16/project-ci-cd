# src/handler.py
import json
import boto3
import os
import logging

# Configura o logger
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Pega o nome da tabela das variáveis de ambiente (boa prática!)
TABLE_NAME = os.environ.get('DYNAMODB_TABLE')

# Decide se está rodando localmente ou não
# No LocalStack, o endpoint da AWS é diferente.
if os.environ.get('AWS_EXECUTION_ENV') is None:
    # Ambiente local (LocalStack)
    dynamodb_resource = boto3.resource('dynamodb', endpoint_url='http://localhost:4566')
    logger.info("Rodando em ambiente local (LocalStack)")
else:
    # Ambiente AWS real
    dynamodb_resource = boto3.resource('dynamodb')
    logger.info("Rodando em ambiente AWS real")
    
table = dynamodb_resource.Table(TABLE_NAME)

def create_transaction(event, context):
    logger.info(f"Evento recebido: {event}")
    
    try:
        body = json.loads(event.get('body', '{}'))
        
        transaction_id = body.get('transaction_id')
        user_id = body.get('user_id')
        amount = body.get('amount')

        if not all([transaction_id, user_id, amount]):
            raise ValueError("Campos 'transaction_id', 'user_id' e 'amount' são obrigatórios.")

        item = {
            'transaction_id': transaction_id,
            'user_id': user_id,
            'amount': str(amount), # DynamoDB prefere números como string em alguns casos
        }
        
        # Salva o item na tabela
        table.put_item(Item=item)
        
        logger.info(f"Transação salva com sucesso: {transaction_id}")

        return {
            'statusCode': 201,
            'body': json.dumps({'message': 'Transação criada com sucesso!', 'item': item})
        }

    except Exception as e:
        logger.error(f"Erro ao processar transação: {e}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error': str(e)})
        }
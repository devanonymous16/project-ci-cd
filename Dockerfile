# Dockerfile
FROM public.ecr.aws/lambda/python:3.9

# Copia o código da função para o diretório de trabalho da imagem
COPY src/handler.py ${LAMBDA_TASK_ROOT}

# Instala o SDK da AWS para Python
RUN pip install boto3

# Define o comando que será executado quando a Lambda for invocada
CMD [ "handler.create_transaction" ]
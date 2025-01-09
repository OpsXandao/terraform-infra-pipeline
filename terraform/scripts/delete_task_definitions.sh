#!/bin/bash

# Definir a região
REGION="us-east-1"

# Listar todas as task definitions
echo "Buscando todas as Task Definitions na região $REGION..."
TASK_DEFINITIONS=$(aws ecs list-task-definitions --region "$REGION" --query "taskDefinitionArns[]" --output text)

# Verificar se existem task definitions
if [ -z "$TASK_DEFINITIONS" ]; then
  echo "Nenhuma Task Definition encontrada na região $REGION."
  exit 0
fi

# Iterar sobre as task definitions e excluir cada uma
echo "Excluindo as Task Definitions..."
for TASK in $TASK_DEFINITIONS; do
  echo "Excluindo: $TASK"
  aws ecs deregister-task-definition --task-definition "$TASK" --region "$REGION"
done

echo "Todas as Task Definitions foram excluídas com sucesso!"

# Deploy Blue-Green on ECS

## Overview
Este projeto implementa uma infraestrutura completa na AWS para deploy Blue/Green de aplicações containerizadas usando Amazon ECS (Elastic Container Service) com instâncias EC2. A infraestrutura é gerenciada através do Terraform e inclui ambientes de desenvolvimento (dev) e produção (prd).

## Arquitetura
A infraestrutura inclui os seguintes componentes principais:

- VPC
- ECS Cluster com Auto Scaling Group
- Application Load Balancer (ALB) com dois target groups (blue/green)
- IAM roles e políticas para ECS tasks e nodes
- CloudWatch Logs para monitoramento
- Security Groups para controle de acesso

## Pré-requisitos

- Terraform >= 1.5.0
- AWS CLI configurado
- Conta AWS com permissões adequadas
- GitHub Actions configurado no repositório

## Configuração do GitHub Actions

### 1. Criar Identity Provider na AWS

Primeiro, você precisa configurar um Identity Provider do GitHub na sua conta AWS. Execute os seguintes passos:

1. Acesse o console AWS
2. Vá para IAM > Identity Providers
3. Clique em "Add Provider"
4. Selecione "OpenID Connect"
5. Configure o Provider URL: `https://token.actions.githubusercontent.com`
6. Audience: `sts.amazonaws.com`

### 2. Criar Role do GitHub Actions

Para criar uma role do GitHub Actions, siga os seguintes passos no console da AWS:

1. Acesse a console AWS e vá para o serviço IAM.
2. Clique em "Roles" e depois em "Create role"
3. Selecione "Web Identity" como tipo de trust entity
4. Em "Identity provider", selecione "token.actions.githubusercontent.com"
5. Em "Audience", selecione "sts.amazonaws.com"
6. Em "GitHub organization", insira seu nome de usuário ou organização do GitHub
7. Clique em "Next"
8. Adicione as seguintes políticas gerenciadas pela AWS:

AmazonEC2FullAccess
AmazonECS_FullAccess
AmazonECSTaskExecutionRolePolicy
AWSCodeDeployRoleForECS
CloudWatchLogsFullAccess
IAMFullAccess

### 3. Políticas Necessárias

A role do GitHub Actions deve ter as seguintes políticas anexadas:

- AmazonEC2FullAccess
- AmazonECS_FullAccess
- AmazonECSTaskExecutionRolePolicy
- AWSCodeDeployRoleForECS
- CloudWatchLogsFullAccess
- IAMFullAccess
- Política personalizada para logs do CD
- Política personalizada para deploys ECS

## Instalação

1. Clone o repositório:
```bash
git clone https://github.com/OpsXandao/terraform-infra-pipeline.git
```

2. Inicialize o Terraform:
```bash
terraform init
```

3. Revise o plano de execução:
```bash
terraform plan
```

4. Aplique a infraestrutura:
```bash
terraform apply
```

## Ambientes

- **Desenvolvimento (dev)**: Ambiente para testes e desenvolvimento
- **Produção (prd)**: Ambiente de produção com configurações otimizadas

## Imagem do container

O projeto utiliza uma aplicação Flask simples para demonstrar o deployment Blue/Green. A aplicação exibe uma página web com uma cor de fundo diferente dependendo da versão do container:

03021914/blue-green:v1 - Exibe uma página com fundo Azul
03021914/blue-green:v2 - Exibe uma página com fundo Verde

## Variáveis de Placeholder do Workflow

Substitua os placeholders abaixo no arquivo de pipeline pelos valores reais de sua infraestrutura antes de executá-la:

- `<AWS_ACCOUNT_ID>`: ID da conta AWS
- `<AWS_REGION>`: Região AWS (ex: us-east-1)
- `<ROLE_NAME>`: Nome do IAM Role
- `<ALB_NAME>`: Nome do Application Load Balancer (ALB)
- `<LISTENER_ID_PROD>`: ID do listener para tráfego de produção (porta 80)
- `<LISTENER_ID_TEST>`: ID do listener para tráfego de teste (porta 5001)
- `<TARGET_GROUP_BLUE>`: Nome do target group do ambiente azul (blue)
- `<TARGET_GROUP_GREEN>`: Nome do target group do ambiente verde (green)
- `<TARGET_GROUP_ID_BLUE>`: ID do target group do ambiente azul (blue)
- `<TARGET_GROUP_ID_GREEN>`: ID do target group do ambiente verde (green)
- `<TASK_FAMILY>`: Nome da família de tarefas ECS
- `<NEW_IMAGE>`: Imagem Docker da nova versão do container
- `<CLUSTER_NAME>`: Nome do cluster ECS
- `<SERVICE_NAME>`: Nome do serviço ECS

## Estrutura do Workflow

O arquivo de workflow do GitHub Actions deve estar localizado em `.github/workflows/deploy.yml` com a seguinte estrutura básica:

```yaml
name: "Blue/Green Deployment"
on:
  push:
    branches:
      - main

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::<AWS_ACCOUNT_ID>:role/<ROLE_NAME>
          aws-region: <AWS_REGION>
```

## Segurança

- A configuração do OIDC provider permite autenticação segura entre GitHub Actions e AWS
- As políticas IAM seguem o princípio do menor privilégio
- Todas as credenciais são gerenciadas através de roles e não chaves de acesso
- O processo de deployment usa listeners separados para teste e produção

# Terraform Modules Documentation

## Module: ALB

### Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

### Resources

| Name | Type |
|------|------|
| aws_lb | resource |
| aws_lb_listener.http | resource |
| aws_lb_listener.test | resource |
| aws_lb_target_group.blue | resource |
| aws_lb_target_group.green | resource |
| aws_security_group.http | resource |

### Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| vpc_id | ID da VPC onde o ALB será criado | `string` | yes |
| public_subnet_ids | Lista de IDs das subnets públicas | `list(string)` | yes |

### Outputs

| Name | Description |
|------|-------------|
| aws_lb_target_group_blue_arn | ARN do target group blue |
| aws_lb_target_group_green_arn | ARN do target group green |
| alb_dns_name | DNS name do ALB |
| alb_url | URL do ALB |
| http_security_group_id | ID do security group HTTP |

## Module: ECS-DEV

### Resources

| Name | Type |
|------|------|
| aws_ecs_cluster.main | resource |
| aws_security_group.ecs_node_sg | resource |
| aws_launch_template.ecs_ec2 | resource |
| aws_autoscaling_group.ecs | resource |
| aws_ecs_capacity_provider.main | resource |
| aws_ecs_cluster_capacity_providers.main | resource |
| aws_cloudwatch_log_group.ecs | resource |
| aws_ecs_task_definition.app | resource |
| aws_ecs_service.app | resource |
| aws_security_group.ecs_task | resource |

### Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| vpc_id | ID da VPC | `string` | yes |
| public_subnet_ids | IDs das subnets públicas | `list(string)` | yes |
| cluster_name | Nome do cluster ECS | `string` | yes |
| container_image | Imagem do container | `string` | yes |
| cidr_block | CIDR block da VPC | `string` | yes |
| http_security_group | ID do security group HTTP | `string` | yes |
| ecs_task_role_arn | ARN da role de task do ECS | `string` | yes |
| ecs_exec_role_arn | ARN da role de execução do ECS | `string` | yes |
| ecs_node_role_arn | ARN da role de node do ECS | `string` | yes |
| ecs_node_profile_arn | ARN do profile de node do ECS | `string` | yes |
| aws_lb_target_group_blue_arn | ARN do target group blue | `string` | yes |
| aws_lb_target_group_green_arn | ARN do target group green | `string` | yes |

### Outputs

| Name | Description |
|------|-------------|
| ecs_task_definition_arn | ARN da task definition |
| ecs_task_definition_family | Family da task definition |
| ecs_task_definition_revision | Revision da task definition |
| ecs_service_name | Nome do serviço ECS |
| ecs_node_sg_id | ID do security group dos nodes ECS |
| ecs_task_sg_id | ID do security group das tasks ECS |

## Module: ECS-PRD

### Resources

| Name | Type |
|------|------|
| aws_ecs_cluster.main | resource |
| aws_launch_template.ecs_ec2 | resource |
| aws_autoscaling_group.ecs | resource |
| aws_ecs_capacity_provider.main | resource |
| aws_ecs_cluster_capacity_providers.main | resource |
| aws_cloudwatch_log_group.ecs | resource |
| aws_ecs_task_definition.app | resource |
| aws_ecs_service.app | resource |

### Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| vpc_id | ID da VPC | `string` | yes |
| public_subnet_ids | IDs das subnets públicas | `list(string)` | yes |
| cluster_name | Nome do cluster ECS | `string` | yes |
| container_image | Imagem do container | `string` | yes |
| cidr_block | CIDR block da VPC | `string` | yes |
| http_security_group | ID do security group HTTP | `string` | yes |
| ecs_task_role_arn | ARN da role de task do ECS | `string` | yes |
| ecs_exec_role_arn | ARN da role de execução do ECS | `string` | yes |
| ecs_node_sg_id | ID do security group dos nodes ECS | `string` | yes |
| ecs_task_sg_id | ID do security group das tasks ECS | `string` | yes |
| aws_lb_target_group_blue_arn | ARN do target group blue | `string` | yes |
| aws_lb_target_group_green_arn | ARN do target group green | `string` | yes |

### Outputs

| Name | Description |
|------|-------------|
| ecs_task_definition_arn | ARN da task definition |

## Module: IAM

### Resources

| Name | Type |
|------|------|
| aws_iam_role.ecs_node_role | resource |
| aws_iam_role_policy_attachment.ecs_node_role_policy | resource |
| aws_iam_instance_profile.ecs_node | resource |
| aws_iam_role.ecs_task_role | resource |
| aws_iam_role.ecs_exec_role | resource |
| aws_iam_role_policy_attachment.ecs_exec_role_policy | resource |
| aws_iam_policy.github_actions_ecs_policy | resource |
| aws_iam_role_policy_attachment.github_actions_ecs_policy_attachment | resource |

### Outputs

| Name | Description |
|------|-------------|
| ecs_node_role_arn | ARN da role do node ECS |
| ecs_node_profile_arn | ARN do profile do node ECS |
| ecs_task_role_arn | ARN da role de task do ECS |
| ecs_exec_role_arn | ARN da role de execução do ECS |

## Como usar esta documentação

1. Cada módulo tem suas próprias variáveis de entrada (inputs) que devem ser fornecidas ao usar o módulo
2. Os outputs de cada módulo podem ser referenciados por outros módulos usando a sintaxe `module.<module_name>.<output_name>`
3. Certifique-se de que todos os requisitos (Requirements) estão atendidos antes de usar os módulos
4. Os recursos (Resources) listados mostram exatamente o que será criado por cada módulo

### Exemplo de uso

```hcl
module "alb" {
  source            = "./alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "ecs-dev" {
  source                        = "./ambiente/dev/ecs"
  vpc_id                        = module.vpc.vpc_id
  public_subnet_ids             = module.vpc.public_subnet_ids
  cluster_name                  = "demo"
  container_image               = "03021914/blue-green:v1"
  cidr_block                    = module.vpc.cidr_block
  http_security_group           = module.alb.http_security_group_id
  ecs_task_role_arn            = module.iam.ecs_task_role_arn
  ecs_exec_role_arn            = module.iam.ecs_exec_role_arn
  ecs_node_role_arn            = module.iam.ecs_node_role_arn
  ecs_node_profile_arn         = module.iam.ecs_node_profile_arn
  aws_lb_target_group_blue_arn = module.alb.aws_lb_target_group_blue_arn
  aws_lb_target_group_green_arn = module.alb.aws_lb_target_group_green_arn
}
```
# Meu Repositório

Componentes

Documento de Política

Define um documento que permite que o serviço EC2 assuma funções IAM (roles). Este é o primeiro passo para estabelecer a cadeia de confiança necessária.
Role IAM
Cria uma função IAM específica para os nós ECS, utilizando o documento de política definido anteriormente. Esta função serve como base para as permissões que as instâncias EC2 terão.
Política ECS
Anexa a política gerenciada AmazonEC2ContainerServiceforEC2Role à role criada. Esta política contém todas as permissões necessárias para que as instâncias EC2 funcionem corretamente como containers ECS, incluindo:

Registro no cluster ECS
Download de imagens de container
Comunicação com o serviço ECS
Interação com outros serviços AWS necessários

Perfil de Instância
Cria um perfil de instância que será usado para atribuir a role IAM às instâncias EC2. Este é o componente final que permite que as instâncias EC2 assumam as permissões definidas.
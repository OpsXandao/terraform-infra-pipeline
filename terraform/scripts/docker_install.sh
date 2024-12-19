#!/bin/bash
# Atualiza a lista de pacotes e instala as atualizações
sudo apt update -y && sudo apt upgrade -y

# Instala dependências necessárias
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Adiciona a chave GPG do repositório do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Adiciona o repositório do Docker
echo | sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Atualiza a lista de pacotes novamente
sudo apt update -y

# Instala o Docker
sudo apt install -y docker-ce

# Baixar a imagem do container
sudo docker pull 03021914/blue-green:v1

sudo docker run -d -p 5000:5000 --name blue-green-container 03021914/blue-green:v1S
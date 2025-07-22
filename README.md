# Projeto de Estudo: Pipeline CI/CD com Jenkins, Docker e Terraform na AWS

## 🎯 Objetivo

Este projeto é um laboratório prático construído como parte da minha preparação para o desafio técnico da vaga de SRE/DevOps. O objetivo é demonstrar, de ponta a ponta, a criação de uma pipeline de CI/CD completa para uma aplicação serverless, utilizando as tecnologias-chave da vaga.

---

## 🛠️ Tecnologias Utilizadas

*   **Controle de Versão:** Git & GitHub
*   **CI/CD:** Jenkins (rodando em Docker)
*   **Cloud Provider:** AWS (Amazon Web Services)
*   **Infraestrutura como Código (IaC):** Terraform
*   **Contêineres:** Docker
*   **Aplicação:** API Serverless com Python, API Gateway e DynamoDB

---

## 🏗️ Arquitetura

*A arquitetura consiste em um servidor Jenkins, hospedado em uma VM no Azure, que escuta por mudanças neste repositório do GitHub. Ao detectar um `push` na branch `main`, ele inicia uma pipeline que:*

1.  *Constrói a imagem Docker da aplicação Python.*
2.  *Envia a imagem para o Amazon ECR (Elastic Container Registry).*
3.  *Executa o Terraform para provisionar ou atualizar a infraestrutura na AWS (API Gateway, Lambda, DynamoDB).*
4.  *A Lambda é configurada para usar a nova imagem Docker enviada ao ECR.*

*(Futuramente, pretendo adicionar um diagrama da arquitetura aqui.)*

---

## 🚀 Como Funciona o Fluxo de CI/CD

1.  **Desenvolvedor:** Faz um `git push` para a branch `main` no GitHub.
2.  **GitHub Webhook:** Notifica o servidor Jenkins sobre a mudança.
3.  **Jenkins Pipeline:**
    *   **Checkout:** Baixa o código-fonte mais recente.
    *   **Build & Push:** Constrói e envia a imagem Docker para o ECR.
    *   **Deploy:** Executa `terraform apply` para sincronizar a infraestrutura com o estado desejado.
4.  **AWS:** A nova versão da aplicação está no ar.
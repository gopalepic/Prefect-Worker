# Prefect Worker on Amazon ECS with Terraform

## Purpose
This project deploys a Prefect Worker on Amazon ECS Fargate using Terraform to orchestrate data workflows via Prefect Cloud. The setup includes a VPC, ECS cluster, IAM roles, and networking components.

## IaC Tool Choice
**Terraform** was chosen for its:
- Cross-cloud flexibility, enabling reuse for other cloud providers if needed.
- Declarative syntax (HCL) for clear resource definitions.
- Strong community support and module ecosystem.

## Prerequisites
- AWS account with permissions for VPC, ECS, IAM, and Secrets Manager.
- Terraform >= 1.2.0 installed.
- AWS CLI configured.
- Prefect Cloud account with API key, account ID, workspace ID, and account URL.

## Deployment Instructions
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/gopalepic/Prefect-Worker.git


## Video  
 video of the whole configuration and setup is provided  
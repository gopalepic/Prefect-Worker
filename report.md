
---
# DevOps Assignment Report

## Tool Choice: Terraform
I chose **Terraform** over CloudFormation for its cross-cloud compatibility, which aligns with modern multi-cloud strategies. Terraform’s HCL is intuitive, and its module system simplifies complex configurations. While CloudFormation is AWS-native, Terraform’s flexibility and community support made it ideal for this task.

## Key Learnings
- **IaC**: Parameterizing configurations (e.g., variables.tf) improves reusability and maintainability.
- **ECS Fargate**: Fargate simplifies container orchestration by eliminating server management, but requires careful networking setup (e.g., private subnets, NAT Gateway).
- **Prefect**: Configuring the worker to connect to Prefect Cloud involves secure handling of API keys via Secrets Manager and precise environment variable setup.

## Challenges and Resolutions
- **Challenge**: Ensuring the Prefect Worker could access Prefect Cloud from private subnets.
  - **Resolution**: Configured a NAT Gateway and verified outbound traffic via the worker’s security group.
- **Challenge**: Debugging worker connectivity issues.
  
- **Challenge**: Managing sensitive data (Prefect API key).
  - **Resolution**: Stored the key in Secrets Manager and granted the task execution role access.

## Suggestions for Improvement

- **Auto-Scaling**: Configure an auto-scaling policy for the ECS service based on CPU/memory or queue depth.
- **Monitoring**: Set up CloudWatch Alarms for worker health and Prefect flow failures.
- **CI/CD**: Integrate Terraform with a CI/CD pipeline (e.g., GitHub Actions) for automated deployments.
- **Cost Optimization**: Use multiple NAT Gateways for high availability or explore VPC Endpoints to reduce NAT costs.


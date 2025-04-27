provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_vpc" "prefect_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_subnet" "public_subnet" {
  count = 3
  vpc_id = aws_vpc.prefect_vpc.id
  cidr_block = cidrsubnet(aws_vpc.prefect_vpc.cidr_block,8,count.index)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name = "prefect-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "private_subnet" {
  count = 3
  vpc_id = aws_vpc.prefect_vpc.id
  cidr_block = cidrsubnet(aws_vpc.prefect_vpc.cidr_block, 8 , count.index + 3)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = {
    Name= "prefect-private-subnet-${count.index}"
  }
}
# Internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.prefect_vpc.id
  
  tags = {
    Name = "prefet-ecs"
  }
}
resource "aws_eip" "nat_eip" {
 domain = "vpc"
 
}


resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.public_subnet[0].id

  tags = {
    Name ="prefect-ecs"
  }
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.prefect_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name="prefect-public-route-table"
  }
}

resource "aws_route_table_association" "public_route_table_association" {
  count = 3
  subnet_id = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.prefect_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "prefect-private-route-table"
  }
}

resource "aws_route_table_association" "private_route_table_association" {
  count = 3
  subnet_id = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

// Cluster 

resource "aws_ecs_cluster" "prefect_cluster" {
  name = "prefect-cluster"
}

resource "aws_service_discovery_private_dns_namespace" "private_dns_namespace" {
  name = "default.prefect.local"
  description = "Private DNS namespace for service discovery"
  vpc = aws_vpc.prefect_vpc.id
}



resource "aws_service_discovery_service" "service_discovery" {
   name = "prefect-service"

   dns_config {
     namespace_id = aws_service_discovery_private_dns_namespace.private_dns_namespace.id

     dns_records {
       type = "A"
       ttl = 60
     }

     routing_policy = "MULTIVALUE"
   }

   health_check_custom_config {
     failure_threshold = 1
   }  

}
# IAM ROLES
# Trust policy allows ecs tasks to assume this role 


resource "aws_iam_role" "prefect_task_execution_role" {
  name = "prefect-task-execution_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "prefect-ecs"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role = aws_iam_role.prefect_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets_manager" {
  role = aws_iam_role.prefect_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# configure aws secrets manager for prefect api KEY 

resource "aws_secretsmanager_secret" "prefect_api_key" {
  name = "prefect-api-key"
  tags = {
    Name = "prefect-ecs"
  }
}

# reading reading api of prefectCloud from secrets manager


resource "aws_iam_role_policy" "secrets_manager_access" {
  name = "PrefectSecretsManagerAccess"
  role = aws_iam_role.prefect_task_execution_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { 
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.prefect_api_key.arn
      }
    ]
  })
}





resource "aws_secretsmanager_secret_version" "prefect_api_key_version" {
  secret_id = aws_secretsmanager_secret.prefect_api_key.id
  secret_string = var.prefect_api_key
}

# prefect worker formation
resource "aws_ecs_task_definition" "dev_worker" {
  family = "dev-worker"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.prefect_task_execution_role.arn

  container_definitions = jsonencode([{
    name = "prefect-worker"
    image = "prefecthq/prefect:2-latest"
    essential = true
    environment = [
      {name = "PREFECT_Account_ID",   value = var.prefect_account_id},
      {name="PREFECT_Workspace_ID",   value=var.prefect_workspace_id},
      {name="PREFECT_Api_URL"  ,      value=var.prefect_account_url },
      
    ]

    secrets = [
      {
        name = "PREFECT_API_KEY",
        valueFrom= aws_secretsmanager_secret.prefect_api_key.arn
      }
    ]

  }])


  tags = {
    Name="prefect-ecs"
  }
}

resource "aws_security_group" "prefect_worker_sg" {
  name        = "prefect-worker-sg"
  description = "Security group for Prefect Worker on ECS"
  vpc_id      = aws_vpc.prefect_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "prefect-ecs"
  }
}


resource "aws_ecs_service" "prefect_worker_service" {
  name = "prefect-worker-service"
  cluster = aws_ecs_cluster.prefect_cluster.id
  task_definition = aws_ecs_task_definition.dev_worker.arn
  desired_count = 1
  launch_type = "FARGATE"

 network_configuration {
   subnets = aws_subnet.private_subnet[*].id
   security_groups = [aws_security_group.prefect_worker_sg.id]
   assign_public_ip = false
 }
  service_registries {
    registry_arn = aws_service_discovery_service.service_discovery.arn
  }
}

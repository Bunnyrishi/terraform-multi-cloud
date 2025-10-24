# AWS Infrastructure Configuration
# Based on PHD E-invoice project architecture

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

########################
# AWS VPC & Networking
########################
resource "aws_vpc" "aws_main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${var.project_name}-aws-vpc"
    Environment = var.environment
    Cloud       = "AWS"
  }
}

resource "aws_subnet" "aws_public_a" {
  vpc_id                  = aws_vpc.aws_main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.project_name}-aws-public-a"
    Environment = var.environment
    Type        = "Public"
  }
}

resource "aws_subnet" "aws_public_b" {
  vpc_id                  = aws_vpc.aws_main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true
  
  tags = {
    Name        = "${var.project_name}-aws-public-b"
    Environment = var.environment
    Type        = "Public"
  }
}

resource "aws_subnet" "aws_private_a" {
  vpc_id            = aws_vpc.aws_main.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "${var.aws_region}a"
  
  tags = {
    Name        = "${var.project_name}-aws-private-a"
    Environment = var.environment
    Type        = "Private"
  }
}

resource "aws_subnet" "aws_private_b" {
  vpc_id            = aws_vpc.aws_main.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "${var.aws_region}b"
  
  tags = {
    Name        = "${var.project_name}-aws-private-b"
    Environment = var.environment
    Type        = "Private"
  }
}

########################
# AWS Internet Gateway & NAT
########################
resource "aws_internet_gateway" "aws_igw" {
  vpc_id = aws_vpc.aws_main.id
  
  tags = {
    Name        = "${var.project_name}-aws-igw"
    Environment = var.environment
  }
}

resource "aws_eip" "aws_nat_eip" {
  domain = "vpc"
  
  tags = {
    Name        = "${var.project_name}-aws-nat-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "aws_nat" {
  allocation_id = aws_eip.aws_nat_eip.id
  subnet_id     = aws_subnet.aws_public_a.id
  
  tags = {
    Name        = "${var.project_name}-aws-nat"
    Environment = var.environment
  }
  
  depends_on = [aws_internet_gateway.aws_igw]
}

########################
# AWS Route Tables
########################
resource "aws_route_table" "aws_public_rt" {
  vpc_id = aws_vpc.aws_main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.aws_igw.id
  }
  
  tags = {
    Name        = "${var.project_name}-aws-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table" "aws_private_rt" {
  vpc_id = aws_vpc.aws_main.id
  
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.aws_nat.id
  }
  
  tags = {
    Name        = "${var.project_name}-aws-private-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "aws_public_a_assoc" {
  subnet_id      = aws_subnet.aws_public_a.id
  route_table_id = aws_route_table.aws_public_rt.id
}

resource "aws_route_table_association" "aws_public_b_assoc" {
  subnet_id      = aws_subnet.aws_public_b.id
  route_table_id = aws_route_table.aws_public_rt.id
}

resource "aws_route_table_association" "aws_private_a_assoc" {
  subnet_id      = aws_subnet.aws_private_a.id
  route_table_id = aws_route_table.aws_private_rt.id
}

resource "aws_route_table_association" "aws_private_b_assoc" {
  subnet_id      = aws_subnet.aws_private_b.id
  route_table_id = aws_route_table.aws_private_rt.id
}

########################
# AWS S3 Buckets
########################
resource "aws_s3_bucket" "aws_app_storage" {
  bucket        = "${var.project_name}-aws-app-storage-${random_id.bucket_suffix.hex}"
  force_destroy = true
  
  tags = {
    Name        = "${var.project_name}-aws-app-storage"
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "aws_backup_storage" {
  bucket        = "${var.project_name}-aws-backup-storage-${random_id.bucket_suffix.hex}"
  force_destroy = true
  
  tags = {
    Name        = "${var.project_name}-aws-backup-storage"
    Environment = var.environment
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

########################
# AWS RDS PostgreSQL
########################
resource "aws_db_subnet_group" "aws_rds_subnet" {
  name       = "${var.project_name}-aws-rds-subnet"
  subnet_ids = [aws_subnet.aws_private_a.id, aws_subnet.aws_private_b.id]
  
  tags = {
    Name        = "${var.project_name}-aws-rds-subnet"
    Environment = var.environment
  }
}

resource "aws_db_parameter_group" "aws_postgres" {
  family = "postgres16"
  name   = "${var.project_name}-aws-postgres-params"
  
  parameter {
    name  = "log_statement"
    value = "all"
  }
  
  tags = {
    Name        = "${var.project_name}-aws-postgres-params"
    Environment = var.environment
  }
}

resource "aws_db_instance" "aws_postgres" {
  identifier             = "${var.project_name}-aws-db"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.8"
  instance_class         = "db.t3.medium"
  db_subnet_group_name   = aws_db_subnet_group.aws_rds_subnet.name
  parameter_group_name   = aws_db_parameter_group.aws_postgres.name
  username               = "app_user"
  password               = random_password.aws_db_password.result
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.aws_rds_sg.id]
  publicly_accessible    = false
  backup_retention_period = 7
  
  tags = {
    Name        = "${var.project_name}-aws-db"
    Environment = var.environment
  }
}

resource "random_password" "aws_db_password" {
  length  = 20
  special = true
}

########################
# AWS ElastiCache Redis
########################
resource "aws_elasticache_subnet_group" "aws_redis_subnet" {
  name       = "${var.project_name}-aws-redis-subnet"
  subnet_ids = [aws_subnet.aws_private_a.id, aws_subnet.aws_private_b.id]
  
  tags = {
    Name        = "${var.project_name}-aws-redis-subnet"
    Environment = var.environment
  }
}

resource "aws_elasticache_cluster" "aws_redis" {
  cluster_id           = "${var.project_name}-aws-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  subnet_group_name    = aws_elasticache_subnet_group.aws_redis_subnet.name
  security_group_ids   = [aws_security_group.aws_redis_sg.id]
  
  tags = {
    Name        = "${var.project_name}-aws-redis"
    Environment = var.environment
  }
}

########################
# AWS Security Groups
########################
resource "aws_security_group" "aws_web_sg" {
  name   = "${var.project_name}-aws-web-sg"
  vpc_id = aws_vpc.aws_main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-aws-web-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "aws_rds_sg" {
  name   = "${var.project_name}-aws-rds-sg"
  vpc_id = aws_vpc.aws_main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_app_sg.id]
  }

  tags = {
    Name        = "${var.project_name}-aws-rds-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "aws_redis_sg" {
  name   = "${var.project_name}-aws-redis-sg"
  vpc_id = aws_vpc.aws_main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.aws_app_sg.id]
  }

  tags = {
    Name        = "${var.project_name}-aws-redis-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "aws_app_sg" {
  name   = "${var.project_name}-aws-app-sg"
  vpc_id = aws_vpc.aws_main.id

  ingress {
    from_port   = 8080
    to_port     = 8084
    protocol    = "tcp"
    security_groups = [aws_security_group.aws_web_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-aws-app-sg"
    Environment = var.environment
  }
}

########################
# AWS EC2 Instances
########################
resource "aws_instance" "aws_web_server" {
  ami                         = "ami-0f5d42f0ba3ba0328" # Amazon Linux 2023 ARM64
  instance_type               = "t4g.medium"
  subnet_id                   = aws_subnet.aws_public_a.id
  vpc_security_group_ids      = [aws_security_group.aws_web_sg.id]
  associate_public_ip_address = true
  
  tags = {
    Name        = "${var.project_name}-aws-web-server"
    Environment = var.environment
  }
}

resource "aws_instance" "aws_app_server" {
  ami                    = "ami-0f5d42f0ba3ba0328" # Amazon Linux 2023 ARM64
  instance_type          = "t4g.large"
  subnet_id              = aws_subnet.aws_private_a.id
  vpc_security_group_ids = [aws_security_group.aws_app_sg.id]
  
  tags = {
    Name        = "${var.project_name}-aws-app-server"
    Environment = var.environment
  }
}
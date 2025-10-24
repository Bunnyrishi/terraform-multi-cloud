########################
# VPC & Networking
########################
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name     = "phd-vpc"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name     = "phd-public-a"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name     = "phd-public-b"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.101.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name     = "phd-private-a"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "ap-south-1b"
  tags = {
    Name     = "phd-private-b"
    Project  = "phd"
    ClientID = "1"
  }
}

########################
# Internet Gateway & Route Table
########################
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name     = "phd-igw"
    Project  = "phd"
    ClientID = "1"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name     = "phd-nat-eip"
    Project  = "phd"
    ClientID = "1"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags = {
    Name     = "phd-nat-gw"
    Project  = "phd"
    ClientID = "1"
  }
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name     = "phd-public-rt"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_route_table_association" "public_a_assoc" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b_assoc" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name     = "phd-private-rt"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_route_table_association" "private_a_assoc" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b_assoc" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}

########################
# S3 Buckets
########################
resource "aws_s3_bucket" "demo_raw" {
  bucket        = "phd-demo1-raw"
  force_destroy = true
  tags = {
    Name     = "phd-demo1-raw"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_s3_bucket" "demo2_raw" {
  bucket        = "phd-demo2-raw"
  force_destroy = true
  tags = {
    Name     = "phd-demo2-raw"
    Project  = "phd"
    ClientID = "1"
  }
}

########################
# Secrets Manager
########################
resource "random_password" "db_pass" {
  length  = 20
  special = true
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "phd/rds/password"
  tags = {
    Name     = "phd-db-password"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "phd_user"
    password = random_password.db_pass.result
    engine   = "postgres"
    host     = aws_db_instance.phd.address
    port     = 5432
    dbname   = "postgres"
  })
}

########################
# RDS Parameter Group
########################
resource "aws_db_parameter_group" "postgres" {
  family = "postgres16"
  name   = "phd-postgres-params"
  
  parameter {
    name  = "log_statement"
    value = "all"
  }
  
  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }
  
  tags = {
    Name     = "phd-postgres-params"
    Project  = "phd"
    ClientID = "1"
  }
}

########################
# RDS (Postgres 16.6) - private
########################

resource "aws_db_subnet_group" "rds" {
  name       = "phd-rds-subnet"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags = {
    Name     = "phd-rds-subnet"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_db_instance" "phd" {
  identifier             = "phd-db"
  allocated_storage      = 20
  engine                 = "postgres"
  engine_version         = "16.8"
  instance_class         = "db.t3.medium"
  db_subnet_group_name   = aws_db_subnet_group.rds.name
  parameter_group_name   = aws_db_parameter_group.postgres.name
  username               = "phd_user"
  password               = random_password.db_pass.result
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  publicly_accessible    = false
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  tags = {
    Name     = "phd-db"
    Project  = "phd"
    ClientID = "1"
  }
}

########################
# ElastiCache Redis
########################
resource "aws_elasticache_parameter_group" "redis" {
  family = "redis7.x"
  name   = "phd-redis-params"
  
  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }
  
  tags = {
    Name     = "phd-redis-params"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "phd-redis-subnet"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags = {
    Name     = "phd-redis-subnet"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "phd-redis"
  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = aws_elasticache_parameter_group.redis.name
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis_sg.id]
  tags = {
    Name     = "phd-redis"
    Project  = "phd"
    ClientID = "1"
  }
}

########################
# SQS
########################
resource "aws_sqs_queue" "irn_email" {
  name = "phd-irn-email"
  tags = {
    Name     = "phd-irn-email"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_sqs_queue" "ewb_email" {
  name = "phd-ewb-email"
  tags = {
    Name     = "phd-ewb-email"
    Project  = "phd"
    ClientID = "1"
  }
}

########################
# IAM Roles for EC2
########################
resource "aws_iam_role" "ec2_ssm_role" {
  name = "phd-ec2-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = {
    Name     = "phd-ec2-ssm-role"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm_attach" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_ssm_profile" {
  name = "phd-ec2-ssm-profile"
  role = aws_iam_role.ec2_ssm_role.name
}

########################
# EC2 Instances (Windows + Linux ARM64)
########################
locals {
  windows_instance = {
    name          = "phd-windows-dashboard"
    ami           = "ami-0c02fb55956c7d316"
    instance_type = "t3a.medium"
    private_ip    = "10.0.2.11"
  }

  linux_instance = {
    name          = "phd-linux-server"
    ami           = "ami-0b69ea66ff7391e80"
    instance_type = "t4g.xlarge"
    private_ip    = "10.0.2.10"
  }
}

resource "aws_security_group" "windows_sg" {
  name   = "phd-windows-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
    description = "RDP from office IP only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "phd-windows-sg"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_security_group" "linux_sg" {
  name   = "phd-linux-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
    description = "SSH from office IP only"
  }

  ingress {
    from_port   = 8080
    to_port     = 8084
    protocol    = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
    description = "Java services from ALB only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "phd-linux-sg"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_security_group_rule" "windows_to_linux" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.linux_sg.id
  source_security_group_id = aws_security_group.windows_sg.id
}

resource "aws_security_group_rule" "linux_to_windows" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.windows_sg.id
  source_security_group_id = aws_security_group.linux_sg.id
}

# Lambda Security Group
resource "aws_security_group" "lambda_sg" {
  name   = "phd-lambda-sg"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "phd-lambda-sg"
    Project  = "phd"
    ClientID = "1"
  }
}

# Allow Lambda to communicate with Linux services
resource "aws_security_group_rule" "lambda_to_linux" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.linux_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
}

# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name   = "phd-rds-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.linux_sg.id, aws_security_group.lambda_sg.id]
    description     = "PostgreSQL from app servers only"
  }

  tags = {
    Name     = "phd-rds-sg"
    Project  = "phd"
    ClientID = "1"
  }
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name   = "phd-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name     = "phd-alb-sg"
    Project  = "phd"
    ClientID = "1"
  }
}

# Redis Security Group
resource "aws_security_group" "redis_sg" {
  name   = "phd-redis-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.linux_sg.id, aws_security_group.lambda_sg.id]
    description     = "Redis from app servers only"
  }

  tags = {
    Name     = "phd-redis-sg"
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_instance" "windows_dashboard" {
  ami                         = "ami-066eb5725566530f0"
  instance_type               = local.windows_instance.instance_type
  subnet_id                   = aws_subnet.public_b.id
  private_ip                  = local.windows_instance.private_ip
  associate_public_ip_address = true
  key_name                    = "phd"
  vpc_security_group_ids      = [aws_security_group.windows_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  tags = {
    Name     = local.windows_instance.name
    Project  = "phd"
    ClientID = "1"
  }
}

resource "aws_instance" "linux_server" {
  ami                         = "ami-0f5d42f0ba3ba0328"
  instance_type               = local.linux_instance.instance_type
  subnet_id                   = aws_subnet.public_b.id
  private_ip                  = local.linux_instance.private_ip
  associate_public_ip_address = true
  key_name                    = "phd"
  vpc_security_group_ids      = [aws_security_group.linux_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_ssm_profile.name
  tags = {
    Name     = local.linux_instance.name
    Project  = "phd"
    ClientID = "1"
  }
}
# Terraform AWS Main Configuration

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Store state in S3 (must be created manually or use local state)
  # Uncomment below for S3 backend
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "devops-lab/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "DevOps-Lab"
      Environment = "Production"
      ManagedBy   = "Terraform"
    }
  }
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets
}

# EC2 Instances Module
module "ec2" {
  source = "./modules/ec2"

  environment   = var.environment
  vpc_id        = module.vpc.vpc_id
  subnet_ids    = module.vpc.public_subnet_ids
  key_name      = var.key_name
  instance_type = var.app_instance_type

  tags = {
    Project = "DevOps-Lab"
  }
}

# Application Load Balancer Module
module "alb" {
  source = "./modules/alb"

  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  security_groups   = module.ec2.app_security_group_ids

  tags = {
    Project = "DevOps-Lab"
  }
}

# Auto Scaling Group Module
module "asg" {
  source = "./modules/asg"

  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.public_subnet_ids
  target_group_arns = module.alb.target_group_arns
  key_name          = var.key_name
  instance_type     = var.app_instance_type

  tags = {
    Project = "DevOps-Lab"
  }
}

# RDS Module (Optional Database)
module "rds" {
  source = "./modules/rds"

  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  db_subnet_group_name = module.vpc.db_subnet_group_name
  security_group_ids   = [module.ec2.db_security_group_id]

  tags = {
    Project = "DevOps-Lab"
  }
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "devops-lab-terraform-state-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Terraform State Bucket"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_caller_identity" "current" {}

# Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = module.alb.alb_dns_name
}

output "alb_zone_id" {
  description = "Zone ID of the ALB"
  value       = module.alb.alb_zone_id
}

output "app1_target_group_arn" {
  description = "ARN of App1 Target Group"
  value       = module.alb.app1_target_group_arn
}

output "app2_target_group_arn" {
  description = "ARN of App2 Target Group"
  value       = module.alb.app2_target_group_arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = module.asg.app_asg_name
}

output "rds_endpoint" {
  description = "RDS Database Endpoint"
  value       = module.rds.db_endpoint
  sensitive   = true
}

# RDS Module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for RDS"
  type        = list(string)
}

variable "db_subnet_group_name" {
  description = "DB Subnet Group Name"
  type        = string
}

variable "security_group_ids" {
  description = "Security Group IDs for RDS"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# RDS Subnet Group (if not created by VPC module)
resource "aws_db_subnet_group" "main" {
  count      = var.db_subnet_group_name == "" ? 1 : 0
  name       = "${var.environment}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.environment}-db-subnet-group"
  })
}

# RDS Instance (MySQL/Aurora)
resource "aws_db_instance" "main" {
  identifier     = "${var.environment}-mysql"
  engine         = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true
  storage_type          = "gp2"

  db_name  = replace(var.environment, "-", "_")
  username = "admin"
  password = "DevOpsLab123!" # Change this in production!

  db_subnet_group_name   = var.db_subnet_group_name != "" ? var.db_subnet_group_name : aws_db_subnet_group.main[0].name
  vpc_security_group_ids = var.security_group_ids

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.environment}-final-snapshot"

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = merge(var.tags, {
    Name = "${var.environment}-mysql"
  })
}

# Outputs
output "db_endpoint" {
  value     = aws_db_instance.main.endpoint
  sensitive = true
}

output "db_address" {
  value = aws_db_instance.main.address
}

output "db_port" {
  value = aws_db_instance.main.port
}

output "db_name" {
  value = aws_db_instance.main.db_name
}

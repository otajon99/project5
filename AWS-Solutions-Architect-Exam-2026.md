# AWS Solutions Architect Professional Exam Questions & Answers 2026

## Exam Overview

| Domain | % of Exam |
|--------|-----------|
| Design Resilient Architectures | 30% |
| Design High-Performing Architectures | 28% |
| Design Secure Applications & Architectures | 24% |
| Design Cost-Optimized Architectures | 18% |

---

## Domain 1: Design Resilient Architectures (30%)

### Question 1: Multi-Region Active-Active Architecture

**Scenario:** Design an active-active architecture for a global e-commerce application requiring 99.99% availability.

**Answer:**

```yaml
# Terraform: Multi-Region Architecture
provider "aws" {
  alias = "primary"
  region = "us-east-1"
}

provider "aws" {
  alias = "secondary"
  region = "us-west-2"
}

# Primary Region VPC
resource "aws_vpc" "primary" {
  provider = aws.primary
  cidr_block = "10.1.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = {
    Name = "primary-vpc"
    Environment = "production"
  }
}

# Secondary Region VPC
resource "aws_vpc" "secondary" {
  provider = aws.secondary
  cidr_block = "10.2.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = {
    Name = "secondary-vpc"
    Environment = "production"
  }
}

# Transit Gateway for VPC Peering
resource "aws_ec2_transit_gateway" "main" {
  provider = aws.primary
  description = "Main Transit Gateway"
  auto_accept_shared_attachments = "enable"
  
  tags = {
    Name = "main-tgw"
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "primary" {
  provider = aws.primary
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id = aws_vpc.primary.id
  
  subnet_ids = aws_subnet.primary[*].id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "secondary" {
  provider = aws.secondary
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  vpc_id = aws_vpc.secondary.id
  
  subnet_ids = aws_subnet.secondary[*].id
}

# Route 53 Health Check and Latency Routing
resource "aws_route53_health_check" "primary" {
  fqdn = aws_lb.primary.dns_name
  port = 443
  type = "HTTPS"
  resource_path = "/health"
  failure_threshold = 3
  request_interval = 10
  
  tags = {
    Name = "primary-health-check"
  }
}

resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name = "app.example.com"
  type = "A"
  
  failover_routing_policy {
    type = "PRIMARY"
  }
  set_identifier = "primary"
  health_check_id = aws_route53_health_check.primary.id
  
  alias {
    name = aws_lb.primary.dns_name
    zone_id = aws_lb.primary.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "app_secondary" {
  zone_id = aws_route53_zone.main.zone_id
  name = "app.example.com"
  type = "A"
  
  failover_routing_policy {
    type = "SECONDARY"
  }
  set_identifier = "secondary"
  
  alias {
    name = aws_lb.secondary.dns_name
    zone_id = aws_lb.secondary.zone_id
    evaluate_target_health = true
  }
}

# Aurora Global Database
resource "aws_rds_global_cluster" "global" {
  global_cluster_identifier = "global-cluster"
  engine = "aurora-postgresql"
  engine_version = "15.3"
  database_name = "mydb"
  storage_encrypted = true
}

resource "aws_rds_cluster" "primary" {
  provider = aws.primary
  cluster_identifier = "primary-cluster"
  global_cluster_identifier = aws_rds_global_cluster.global.id
  engine = aws_rds_global_cluster.global.engine
  engine_mode = "provisioned"
  engine_version = aws_rds_global_cluster.global.engine_version
  database_name = "mydb"
  master_username = "admin"
  master_password = var.db_password
  skip_final_snapshot = true
  backup_retention_period = 7
  
  tags = {
    Environment = "production"
  }
}

resource "aws_rds_cluster_instance" "primary_instances" {
  count = 3
  provider = aws.primary
  identifier = "primary-${count.index}"
  cluster_identifier = aws_rds_cluster.primary.id
  instance_class = "db.r7g.xlarge"
  engine = aws_rds_cluster.primary.engine
  engine_version = aws_rds_cluster.primary.engine_version
}

resource "aws_rds_cluster" "secondary" {
  provider = aws.secondary
  cluster_identifier = "secondary-cluster"
  global_cluster_identifier = aws_rds_global_cluster.global.id
  engine = aws_rds_global_cluster.global.engine
  engine_mode = "provisioned"
  engine_version = aws_rds_global_cluster.global.engine_version
  skip_final_snapshot = true
}

# S3 Cross-Region Replication
resource "aws_s3_bucket" "primary" {
  bucket = "myapp-primary"
  
  versioning {
    enabled = true
  }
  
  replication_configuration {
    role = aws_iam_role.replication.arn
    
    rules {
      id = "replicate-to-secondary"
      status = "Enabled"
      destination {
        bucket = aws_s3_bucket.secondary.arn
        storage_class = "STANDARD_IA"
        replica_kms_key_id = aws_kms_key.replication.arn
      }
    }
  }
}

resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket = "myapp-secondary"
  
  versioning {
    enabled = true
  }
}
```

---

### Question 2: Disaster Recovery Strategies

**Scenario:** Compare and implement different DR strategies for a critical banking application.

**Answer:**

```
┌─────────────────────────────────────────────────────────────────────────┐
│                  DISASTER RECOVERY STRATEGIES                         │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  RTO (Recovery Time Objective): Maximum acceptable downtime              │
│  RPO (Recovery Point Objective): Maximum acceptable data loss           │
│                                                                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐       │
│  │    Backup &     │  │    Pilot      │  │    Warm      │       │
│  │    Restore      │  │    Light      │  │    Standby   │       │
│  ├─────────────────┤  ├─────────────────┤  ├─────────────────┤       │
│  │ RTO: Hours     │  │ RTO: Minutes   │  │ RTO: Minutes   │       │
│  │ RPO: Days      │  │ RPO: Hours     │  │ RPO: Seconds  │       │
│  │ Cost: $        │  │ Cost: $$       │  │ Cost: $$$     │       │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘       │
│                                                                          │
│  ┌─────────────────┐  ┌─────────────────┐                             │
│  │    Hot       │  │   Multi-Site  │                             │
│  │    Standby      │  │   Active-Active │                             │
│  ├─────────────────┤  ├─────────────────┤                             │
│  │ RTO: Seconds   │  │ RTO: Zero      │                             │
│  │ RPO: Zero      │  │ RPO: Zero      │                             │
│  │ Cost: $$$$     │  │ Cost: $$$$$    │                             │
│  └─────────────────┘  └─────────────────┘                             │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

```yaml
# DR Strategy Implementation: Warm Standby with Pilot Light

# Primary Region: Full Capacity
resource "aws_ecs_cluster" "primary" {
  name = "production-cluster"
  
  setting {
    name = "containerInsights"
    value = "enabled"
  }
  
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    base = 1
    weight = 100
    capacity_provider = "FARGATE"
  }
}

# DR Region: Minimal Capacity (Pilot Light)
resource "aws_ecs_cluster" "dr" {
  provider = aws.dr
  name = "dr-cluster"
  
  setting {
    name = "containerInsights"
    value = "enabled"
  }
  
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    base = 1
    weight = 100
    capacity_provider = "FARGATE"
  }
}

# Database: Aurora Global with Automatic Failover
resource "aws_rds_global_cluster" "dr_global" {
  global_cluster_identifier = "dr-global"
  engine = "aurora-postgresql"
  engine_version = "15.3"
  
  storage_encrypted = true
}

# SNS Topic for DR Notifications
resource "aws_sns_topic" "dr_alerts" {
  name = "dr-alerts"
  
  kms_master_key_id = aws_kms_key.sns.id
}

resource "aws_sns_topic_subscription" "dr_email" {
  topic_arn = aws_sns_topic.dr_alerts.arn
  protocol = "email"
  endpoint = "ops@example.com"
}

# CloudWatch Events for DR Automation
resource "aws_cloudwatch_event_rule" "dr_trigger" {
  name = "dr-trigger"
  description = "Trigger DR failover"
  
  event_pattern = jsonencode({
    source = ["aws.rds"]
    detail-type = ["RDS DB Cluster Event"]
    detail = {
      EventCategories = ["failover"]
    }
  })
}

resource "aws_cloudwatch_event_target" "dr_lambda" {
  rule = aws_cloudwatch_event_rule.dr_trigger.name
  target_id = "TriggerDRLambda"
  arn = aws_lambda_function.dr_failover.arn
}
```

---

### Question 3: Auto Scaling Architecture

**Answer:**

```yaml
# Auto Scaling with Multiple Policies

resource "aws_appautoscaling_target" "ecs" {
  max_capacity = 100
  min_capacity = 2
  
  resource_id = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

# Target Tracking - CPU
resource "aws_appautoscaling_policy" "cpu" {
  name = "cpu-target-tracking"
  policy_type = "TargetTrackingScaling"
  
  resource_id = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace = aws_appautoscaling_target.ecs.service_namespace
  
  target_tracking_scaling_policy_configuration {
    target_value = 70
    scale_in_cooldown = 300
    scale_out_cooldown = 60
    
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# Target Tracking - Memory
resource "aws_appautoscaling_policy" "memory" {
  name = "memory-target-tracking"
  policy_type = "TargetTrackingScaling"
  
  resource_id = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace = aws_appautoscaling_target.ecs.service_namespace
  
  target_tracking_scaling_policy_configuration {
    target_value = 80
    scale_in_cooldown = 300
    scale_out_cooldown = 60
    
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

# Step Scaling Policy - Custom Metric
resource "aws_appautoscaling_policy" "request_count" {
  name = "request-count-scaling"
  policy_type = "StepScaling"
  
  resource_id = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace = aws_appautoscaling_target.ecs.service_namespace
  
  step_adjustment {
    scaling_adjustment = 1
    metric_interval_lower_bound = 0
    metric_interval_upper_bound = 10
  }
  step_adjustment {
    scaling_adjustment = 2
    metric_interval_lower_bound = 10
    metric_interval_upper_bound = 20
  }
  step_adjustment {
    scaling_adjustment = 3
    metric_interval_lower_bound = 20
  }
  
  metric_aggregation_type = "Average"
  estimated_instance_warmup = 60
}

# Scheduled Scaling
resource "aws_appautoscaling_schedule" "morning_rampup" {
  name = "morning-rampup"
  service_namespace = "ecs"
  resource_id = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  
  schedule = "cron(30 6 * * ? *)"
  timezone = "UTC"
  
  min_capacity = 10
  max_capacity = 100
}

resource "aws_appautoscaling_schedule" "evening_rampdown" {
  name = "evening-rampdown"
  service_namespace = "ecs"
  resource_id = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  
  schedule = "cron(0 22 * * ? *)"
  timezone = "UTC"
  
  min_capacity = 2
  max_capacity = 100
}
```

---

## Domain 2: Design High-Performing Architectures (28%)

### Question 4: Global Content Delivery Architecture

**Answer:**

```yaml
# CloudFront with Multi-Origin Architecture

resource "aws_cloudfront_distribution" "main" {
  enabled = true
  price_class = "PriceClass_All"
  
  origin {
    origin_id = "alb-origin"
    domain_name = aws_lb.main.dns_name
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }
  
  origin {
    origin_id = "s3-static"
    domain_name = aws_s3_bucket.static.website_endpoint
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
    }
  }
  
  origin {
    origin_id = "api-gateway"
    domain_name = "${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com"
    origin_path = "/prod"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }
  
  default_cache_behavior {
    target_origin_id = "alb-origin"
    
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
      headers = ["Accept", "Accept-Language", "Authorization", "Content-Type"]
    }
    
    min_ttl = 0
    default_ttl = 3600
    max_ttl = 86400
    
    lambda_function_association {
      event_type = "origin-request"
      lambda_arn = aws_lambda_function.edge_request.arn
    }
  }
  
  ordered_cache_behaviors {
    path_pattern = "/api/*"
    target_origin_id = "api-gateway"
    viewer_protocol_policy = "https-only"
    
    allowed_methods = ["GET", "HEAD", "OPTIONS", "POST", "PUT", "DELETE"]
    cached_methods = ["GET", "HEAD", "OPTIONS"]
    
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
    
    min_ttl = 0
    default_ttl = 0
    max_ttl = 0
  }
  
  ordered_cache_behaviors {
    path_pattern = "*.jpg,*.jpeg,*.png,*.gif,*.webp"
    target_origin_id = "s3-static"
    viewer_protocol_policy = "https-only"
    
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    
    min_ttl = 86400
    default_ttl = 604800
    max_ttl = 31536000
  }
  
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.main.arn
    ssl_support_method = "sni-only"
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations = ["US", "CA", "GB", "DE", "FR", "JP", "AU"]
    }
  }
  
  logging_config {
    include_cookies = false
    bucket = aws_s3_bucket.logs.bucket_domain_name
    prefix = "cloudfront"
  }
}

# Lambda@Edge for Request/Response Transformation
resource "aws_lambda_function" "edge_request" {
  function_name = "edge-request-transformer"
  handler = "index.handler"
  runtime = "nodejs18.x"
  role = aws_iam_role.lambda_edge.arn
  
  filename = "lambda_edge.zip"
  source_code_hash = filebase64sha256("lambda_edge.zip")
  
  memory_size = 128
  timeout = 5
  
  lifecycle {
    create_before_destroy = true
  }
}

# Global Accelerator for Static IP
resource "aws_globalaccelerator_accelerator" "main" {
  name = "my-accelerator"
  enabled = true
  
  ip_address_type = "IPV4"
  
  attributes {
    flow_logs_enabled = true
    flow_logs_s3_bucket = aws_s3_bucket.flow_logs.bucket
    flow_logs_s3_prefix = "global-accelerator/"
  }
}

resource "aws_globalaccelerator_listener" "http" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  protocol = "TCP"
  
  port_range {
    from_port = 80
    to_port = 80
  }
}

resource "aws_globalaccelerator_listener" "https" {
  accelerator_arn = aws_globalaccelerator_accelerator.main.id
  protocol = "TCP"
  
  port_range {
    from_port = 443
    to_port = 443
  }
}

resource "aws_globalaccelerator_endpoint_group" "primary" {
  listener_arn = aws_globalaccelerator_listener.https.id
  endpoint_group_region = "us-east-1"
  
  health_check_interval_seconds = 10
  health_check_path = "/health"
  health_check_protocol = "HTTPS"
  threshold_count = 3
  
  endpoint_configuration {
    endpoint_id = aws_lb.primary.arn
    weight = 100
  }
}

resource "aws_globalaccelerator_endpoint_group" "secondary" {
  listener_arn = aws_globalaccelerator_listener.https.id
  endpoint_group_region = "us-west-2"
  
  health_check_interval_seconds = 10
  health_check_path = "/health"
  health_check_protocol = "HTTPS"
  threshold_count = 3
  
  endpoint_configuration {
    endpoint_id = aws_lb.secondary.arn
    weight = 100
  }
}
```

---

### Question 5: Database Performance Optimization

**Answer:**

```yaml
# RDS Performance Optimization

resource "aws_rds_cluster" "optimized" {
  cluster_identifier = "optimized-cluster"
  engine = "aurora-postgresql"
  engine_version = "15.3"
  
  database_name = "mydb"
  master_username = "admin"
  master_password = var.db_password
  
  # Performance Settings
  backtrack_window = 86400
  
  # Storage
  storage_encrypted = true
  kms_key_id = aws_kms_key.rds.id
  
  # Backup
  backup_retention_period = 30
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "mon:04:00-mon:05:00"
  
  # Network
  db_subnet_group_name = aws_rds_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  
  # Monitoring
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn
  
  # Performance Insights
  performance_insights_enabled = true
  performance_insights_retention_period = 31
  performance_insights_kms_key_id = aws_kms_key.rds.id
  
  # Serverless (optional)
  # serverlessv2_scaling_configuration {
  #   min_capacity = 2
  #   max_capacity = 64
  # }
  
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
}

# Custom Parameter Group
resource "aws_rds_cluster_parameter_group" "main" {
  name = "optimized-cluster-params"
  family = "aurora-postgresql15"
  
  parameter {
    name = "max_connections"
    value = "GREATER:100"
  }
  
  parameter {
    name = "shared_buffers"
    value = "GREATER:24576"  # 24GB
  }
  
  parameter {
    name = "effective_cache_size"
    value = "GREATER:73728"  # 72GB
  }
  
  parameter {
    name = "maintenance_work_mem"
    value = "GREATER:524288"  # 512MB
  }
  
  parameter {
    name = "checkpoint_completion_target"
    value = "0.9"
  }
  
  parameter {
    name = "wal_buffers"
    value = "16MB"
  }
  
  parameter {
    name = "default_statistics_target"
    value = "100"
  }
  
  parameter {
    name = "random_page_cost"
    value = "1.1"  # For SSD storage
  }
  
  parameter {
    name = "effective_io_concurrency"
    value = "200"
  }
  
  parameter {
    name = "work_mem"
    value = "4194"
  }
  
  parameter {
    name = "min_wal_size"
    value = "2GB"
  }
  
  parameter {
    name = "max_wal_size"
    value = "8GB"
  }
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id = "redis-cluster"
  engine = "redis"
  engine_version = "7.0"
  node_type = "cache.r7g.large"
  num_cache_nodes = 2
  parameter_group_name = aws_elasticache_parameter_group.main.name
  
  port = 6379
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token_enabled = true
  auto_minor_version_upgrade = true
  
  snapshot_retention_limit = 7
  snapshot_window = "03:00-05:00"
  
  log_delivery_configuration {
    destination = aws_cloudwatch_log_group.redis_slow.name
    destination_type = "cloudwatch-logs"
    log_format = "json"
    log_type = "slow-log"
  }
  
  log_delivery_configuration {
    destination = aws_cloudwatch_log_group.redis_engine.name
    destination_type = "cloudwatch-logs"
    log_format = "json"
    log_type = "engine-log"
  }
}
```

---

### Question 6: Event-Driven Architecture

**Answer:**

```yaml
# Event-Driven Architecture with EventBridge

resource "aws_cloudtrail" "main" {
  name = "main-trail"
  s3_bucket_name = aws_s3_bucket.trail.id
  is_multi_region_trail = true
  enable_log_file_validation = true
  is_organization_trail = false
  
  event_selector {
    read_write_type = "All"
    include_management_events = true
    
    data_resource {
      type = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }
}

# EventBridge Event Bus
resource "aws_cloudwatch_event_bus" "main" {
  name = "main-event-bus"
  
  tags = {
    Environment = "production"
  }
}

resource "aws_cloudwatch_event_bus" "partner" {
  name = "partner-event-bus"
  
  tags = {
    Environment = "production"
  }
}

# EventBridge Rule: S3 to Lambda
resource "aws_cloudwatch_event_rule" "s3_upload" {
  name = "s3-upload-rule"
  description = "Trigger Lambda on S3 upload"
  
  event_bus_name = aws_cloudwatch_event_bus.main.name
  
  event_pattern = jsonencode({
    source = ["aws.s3"]
    detail-type = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.upload.bucket]
      }
      object = {
        key = [{
          prefix = "uploads/"
        }]
      }
    }
  })
  
  target {
    id = "lambda-processor"
    arn = aws_lambda_function.processor.arn
  }
}

# EventBridge Rule: DynamoDB to SQS
resource "aws_cloudwatch_event_rule" "dynamodb_streams" {
  name = "dynamodb-streams-rule"
  
  event_bus_name = aws_cloudwatch_event_bus.main.name
  
  event_source_arn = aws_dynamodb_table.main.stream_arn
  
  target {
    id = "sqs-dlq"
    arn = aws_sqs_queue.main.arn
    batch_size = 10
    retry_policy {
      maximum_retry_attempts = 3
      maximum_event_age_in_seconds = 300
    }
  }
}

# SQS with Dead Letter Queue
resource "aws_sqs_queue" "main" {
  name = "main-queue"
  
  fifo_queue = false
  
  delay_seconds = 0
  max_message_size = 262144  # 256KB
  message_retention_seconds = 1209600  # 14 days
  receive_wait_time_seconds = 20
  visibility_timeout_seconds = 300
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount = 3
  })
  
  tags = {
    Environment = "production"
  }
}

resource "aws_sqs_queue" "dlq" {
  name = "main-queue-dlq"
  
  message_retention_seconds = 1209600  # 14 days
  
  tags = {
    Environment = "production"
    Type = "dead-letter-queue"
  }
}

# Kinesis Data Streams
resource "aws_kinesis_stream" "main" {
  name = "main-stream"
  
  shard_count = 4
  retention_period = 168  # 7 days
  
  encryption_type = "KMS"
  kms_key_id = aws_kms_key.kinesis.id
  
  shard_level_metrics = [
    "IncomingBytes",
    "IncomingRecords",
    "IteratorAgeMilliseconds",
    "OutgoingBytes",
    "OutgoingRecords",
    "ReadProvisionedThrottles",
    "WriteProvisionedThrottles"
  ]
  
  tags = {
    Environment = "production"
  }
}

# Kinesis Firehose for Real-time Analytics
resource "aws_kinesis_firehose_delivery_stream" "main" {
  name = "main-firehose"
  
  destination = "extended_s3"
  
  extended_s3_configuration {
    bucket_arn = aws_s3_bucket.firehose.arn
    role_arn = aws_iam_role.firehose.arn
    
    buffering_size = 64  # MB
    buffering_interval = 60  # seconds
    
    compression_format = "GZIP"
    encryption_configuration {
      kms_encryption_config {
        aws_kms_key_short_arn = aws_kms_key.firehose.arn
      }
    }
    
    error_output_prefix = "errors/#{YYYY}/#{MM}/#{DD}/"
    prefix = "data/#{YYYY}/#{MM}/#{DD}/#{HH}/"
    
    processing_configuration {
      enabled = true
      processors {
        type = "Lambda"
        parameters {
          parameter_name = "LambdaArn"
          parameter_value = aws_lambda_function.firehose_processor.arn
        }
      }
    }
  }
}
```

---

## Domain 3: Design Secure Applications & Architectures (24%)

### Question 7: Zero Trust Security Architecture

**Answer:**

```yaml
# Zero Trust Architecture Implementation

# VPC with Public/Private/Isolated Subnets
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  
  tags = {
    Name = "zero-trust-vpc"
    Classification = "internal"
  }
}

# Security: Network ACLs (Stateless)
resource "aws_network_acl" "public" {
  vpc_id = aws_vpc.main.id
  subnet_ids = aws_subnet.public[*].id
  
  egress {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }
  
  ingress {
    protocol = "-1"
    rule_no = 100
    action = "allow"
    cidr_block = "0.0.0.0/0"
  }
  
  tags = {
    Name = "public-nacl"
  }
}

# Security Groups (Stateful) - Application Tier
resource "aws_security_group" "application" {
  name = "application-sg"
  description = "Security group for application tier"
  vpc_id = aws_vpc.main.id
  
  # Inbound: Only from ALB
  ingress {
    description = "HTTP from ALB"
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  # Outbound: Only to Database
  egress {
    description = "To database"
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    security_groups = [aws_security_group.database.id]
  }
  
  # Egress: Only to approved destinations
  egress {
    description = "HTTPS to internet"
    from_port = 443
    to_port = 443
    protocol = "tcp
    cidr_blocks = ["10.0.0.0/8"]
  }
}

# IAM Roles with Service Control Policies
resource "aws_iam_role" "ecs_task" {
  name = "ecs-task-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "task_policy" {
  name = "ecs-task-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "S3Access"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::my-app-data/*"
        ]
      },
      {
        Sid = "DynamoDBAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Resource = [
          aws_dynamodb_table.main.arn
        ]
      },
      {
        Sid = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "arn:aws:secretsmanager:*:*:secret:my-app/*"
        ]
      }
    ]
  })
}

# Secrets Manager with Automatic Rotation
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "prod/db-credentials"
  
  recovery_window_in_days = 30
  
  rotation_lambda_arn = aws_lambda_function.rotation.arn
  
  rotation_rules {
    automatically_after_days = 30
  }
  
  tags = {
    Classification = "confidential"
    Rotation = "enabled"
  }
}

# WAF Web ACL with Rate Limiting
resource "aws_wafv2_web_acl" "main" {
  name = "main-web-acl"
  scope = "REGIONAL"
  
  default_action {
    allow {}
  }
  
  rule {
    name = "rate-limit"
    priority = 1
    
    action {
      block {
        custom_response {
          response_code = 429
          custom_response_body_key = "rate-limit-body"
        }
      }
    }
    
    statement {
      rate_based_statement {
        limit = 10000
        aggregate_key_type = "IP"
      }
    }
    
    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "rate-limit-metric"
    }
  }
  
  rule {
    name = "aws-common-rules"
    priority = 100
    
    override_action {
      count {}
    }
    
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name = "AWSManagedRulesCommonRuleSet"
      }
    }
    
    visibility_config {
      sampled_requests_enabled = true
      cloudwatch_metrics_enabled = true
      metric_name = "aws-common-rules"
    }
  }
  
  visibility_config {
    sampled_requests_enabled = true
    cloudwatch_metrics_enabled = true
    metric_name = "main-web-acl"
  }
}
```

---

### Question 8: Encryption at Rest and in Transit

**Answer:**

```yaml
# Comprehensive Encryption Configuration

# KMS Key with Multiple Grants
resource "aws_kms_key" "main" {
  description = "Main encryption key for production"
  
  key_usage = "ENCRYPT_DECRYPT"
  key_spec = "SYMMETRIC_DEFAULT"
  
  enable_key_rotation = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Id = "key-policy"
    Statement = [
      {
        Sid = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*"
        Resource = "*"
      },
      {
        Sid = "Allow use of key for EBS"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:CreateGrant",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ForAnyValue:StringEquals = {
            "kms:EncryptionContextKeys" = ["aws:ebs:id"]
          }
        }
      },
      {
        Sid = "Allow use of key for RDS"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      },
      {
        Sid = "Allow Lambda function access"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt"
        ]
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Environment = "production"
    Classification = "critical"
  }
}

# S3 with Server-Side Encryption
resource "aws_s3_bucket" "encrypted" {
  bucket = "encrypted-data-bucket"
  
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
        kms_master_key_id = aws_kms_key.main.arn
      }
      
      bucket_key_enabled = true
    }
  }
  
  versioning {
    enabled = true
  }
  
  lifecycle_rule {
    enabled = true
    
    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days = 90
      storage_class = "GLACIER"
    }
    
    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class = "STANDARD_IA"
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# ALB with TLS Termination
resource "aws_lb" "main" {
  name = "main-alb"
  internal = false
  load_balancer_type = "application"
  
  enable_cross_zone_load_balancing = true
  enable_deletion_protection = true
  
  security_groups = [aws_security_group.alb.id]
  subnets = aws_subnet.public[*].id
  
  idle_timeout = 3600
  
  desync_mitigation_mode = "defensive"
  
  drop_invalid_header_fields_enabled = true
  
  access_logs {
    bucket = aws_s3_bucket.alb_logs.id
    prefix = "alb-logs"
    enabled = true
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate {
    certificate_arn = aws_acm_certificate.main.arn
  }
  
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# ACM Certificate with Validation
resource "aws_acm_certificate" "main" {
  domain_name = "*.example.com"
  validation_method = "DNS"
  
  options {
    certificate_transparency_logging_preference = "ENABLED"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# DynamoDB with Encryption at Rest
resource "aws_dynamodb_table" "main" {
  name = "main-table"
  
  hash_key = "pk"
  range_key = "sk"
  
  billing_mode = "PROVISIONED"
  read_capacity = 100
  write_capacity = 100
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  
  ttl {
    attribute_name = "ttl"
    enabled = true
  }
  
  global_secondary_index {
    name = "gsi1"
    hash_key = "gsi1pk"
    range_key = "gsi1sk"
    projection_type = "ALL"
    read_capacity = 50
    write_capacity = 50
  }
}
```

---

## Domain 4: Design Cost-Optimized Architectures (18%)

### Question 9: Cost Optimization Strategies

**Answer:**

```yaml
# Cost-Optimized Architecture

# Reserved Instances for Predictable Workloads
resource "aws_ec2_reserved_instance" "compute" {
  offering_type = "Standard"
  reserved_instance_type = "m5.large"
  instance_count = 10
  availability_zone = "us-east-1a"
  scope = "Availability Zone"
  
  tags = {
    Environment = "production"
    CostCenter = "engineering"
  }
}

# Savings Plans for Flexible Usage
resource "aws_savingsplans" "compute" {
  commitment = "0.50"
  payment_option = "No Upfront"
  plan_type = "Compute"
  savings_plan_offering_id = "h7g1d5f3-4c6b-4a8e-9f2d-1e3b5c7d8f9e"
  
  time {
    start = "2024-01-01T00:00:00Z"
    end = "2025-01-01T00:00:00Z"
  }
}

# S3 Intelligent Tiering
resource "aws_s3_bucket" "tiered_storage" {
  bucket = "tiered-storage-bucket"
  
  lifecycle_rule {
    id = "intelligent-tiering"
    enabled = true
    
    filter {
      prefix = "data/"
    }
    
    transition {
      days = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

# Spot Instances for Batch Processing
resource "aws_launch_template" "spot_lt" {
  name = "spot-launch-template"
  
  instance_market_options {
    market_type = "spot"
    
    spot_options {
      allocation_strategy = "capacity-optimized"
      instance_interruption_behavior = "terminate"
      max_price = "0.05"
    }
  }
  
  monitoring {
    enabled = true
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Lifecycle = "spot"
      Environment = "batch-processing"
    }
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name
  
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description = "Expire untagged images older than 14 days"
        selection = {
          tagStatus = "untagged"
          tagPrefixList = []
          countType = "sinceImagePushed"
          countUnit = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description = "Keep only last 5 tagged images"
        selection = {
          tagStatus = "tagged"
          tagPrefixList = ["v"]
          countType = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# CloudWatch Billing Alerts
resource "aws_cloudwatch_metric_alarm" "billing_alarm" {
  alarm_name = "estimated-charges-alarm"
  
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = 1
  metric_name = "EstimatedCharges"
  namespace = "AWS/Billing"
  period = 21600  # 6 hours
  statistic = "Maximum"
  threshold = 1000
  alarm_description = "This metric monitors estimated AWS charges"
  
  treat_missing_data = "notBreaching"
}

# Cost Allocation Tags
resource "aws_resourcegroups_group" "cost_tracking" {
  name = "cost-tracking-group"
  
  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"]
      TagFilters = [
        {
          Key = "Environment"
          Values = ["production", "staging"]
        }
      ]
    })
  }
}

# Lambda Power Tuning
resource "aws_lambda_function" "power_tuner" {
  function_name = "power-tuner"
  runtime = "nodejs18.x"
  handler = "index.handler"
  role = aws_iam_role.power_tuner.arn
  
  filename = "power_tuner.zip"
  source_code_hash = filebase64sha256("power_tuner.zip")
  
  memory_size = 128
  timeout = 10
  
  environment {
    variables = {
      POWER_TUNING_MODE = "auto"
    }
  }
}

# Cost Explorer Budget
resource "aws_budgets_budget" "main" {
  name = "monthly-budget"
  budget_type = "COST"
  
  limit_amount = "1000"
  limit_unit = "USD"
  time_unit = "MONTHLY"
  
  cost_filters = {
    LinkedAccount = [data.aws_caller_identity.current.account_id]
  }
  
  notification {
    comparison_operator = "GREATER_THAN"
    threshold = 80
    threshold_type = "PERCENTAGE"
    notification_type = "ACTUAL"
    
    subscriber {
      address = "ops@example.com"
      subscription_type = "EMAIL"
    }
  }
}
```

---

## Practice Exam Questions

### Question 10: Multi-Choice
**Q:** What is the maximum RPO achievable with Aurora Global Database?

A) 1 second
B) 1 minute
C) 5 minutes
D) 1 hour

**Answer: A** - Aurora Global Database provides RPO of approximately 1 second with automatic cross-region replication.

### Question 11: Multi-Choice
**Q:** Which AWS service should be used for distributing traffic to multiple Lambda functions?

A) CloudFront
B) API Gateway
C) Route 53
D) ELB

**Answer: B** - API Gateway can route to multiple Lambda functions using different integration configurations.

### Question 12: Scenario-Based
**Q:** Design a solution for a company needing to process 10 million events per day with 99.9% availability. Events must be processed within 5 minutes. Evaluate your design.

**Answer:**
1. **Kinesis Data Streams** - Handle 10M events/day (~115/sec average, ~1000/sec peak)
2. **Lambda Consumers** - Auto-scaling, process within SLA
3. **Dead Letter Queue** - SQS for failed messages
4. **DynamoDB** - Store processed results with on-demand capacity
5. **CloudWatch** - Monitoring and alerting
6. **Multi-AZ** - High availability across AZs

---

## Answer Key Summary

| Question | Topic | Key Concept |
|----------|-------|-------------|
| Q1 | Multi-Region | Global resources, Route 53 routing |
| Q2 | DR Strategies | RTO/RPO tradeoffs, Aurora Global |
| Q3 | Auto Scaling | Multiple policies, scheduled scaling |
| Q4 | CDN | CloudFront, Lambda@Edge, Global Accelerator |
| Q5 | Database | Aurora optimization, parameter tuning |
| Q6 | Event-Driven | EventBridge, Kinesis, SQS |
| Q7 | Zero Trust | Security groups, IAM, WAF |
| Q8 | Encryption | KMS, ACM, S3 SSE |
| Q9 | Cost Optimization | Reserved Instances, Savings Plans |
| Q10 | Multi-Choice | Aurora Global RPO = 1 second |
| Q11 | Multi-Choice | API Gateway for Lambda routing |
| Q12 | Scenario | Kinesis + Lambda architecture |

---

**Good luck with your AWS Solutions Architect exam!**

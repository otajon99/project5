# Auto Scaling Group Module

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for ASG"
  type        = list(string)
}

variable "target_group_arns" {
  description = "Target group ARNs for ASG"
  type        = list(string)
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Launch Template for App1
resource "aws_launch_template" "app1" {
  name_prefix   = "${var.environment}-app1-"
  image_id      = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd php mysql
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>App1 - Server: $(hostname)</h1>" > /var/www/html/index.html
              EOF
  )

  vpc_security_group_ids = [var.security_group_id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.environment}-app1-instance"
      App  = "app1"
    })
  }

  monitoring {
    enabled = true
  }
}

# Launch Template for App2
resource "aws_launch_template" "app2" {
  name_prefix   = "${var.environment}-app2-"
  image_id      = "ami-0c55b159cbfafe1f0" # Amazon Linux 2
  instance_type = var.instance_type
  key_name      = var.key_name

  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd php mysql
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>App2 - Server: $(hostname)</h1>" > /var/www/html/index.html
              EOF
  )

  vpc_security_group_ids = [var.security_group_id]

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, {
      Name = "${var.environment}-app2-instance"
      App  = "app2"
    })
  }

  monitoring {
    enabled = true
  }
}

variable "security_group_id" {
  description = "Security group ID for instances"
  type        = string
}

# Auto Scaling Group for App1
resource "aws_autoscaling_group" "app1" {
  name                      = "${var.environment}-app1-asg"
  vpc_zone_identifier       = var.subnet_ids
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 4
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app1.id
    version = "$Latest"
  }

  target_group_arns = [var.target_group_arns[0]]

  tag {
    key                 = "Name"
    value               = "${var.environment}-app1-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "App"
    value               = "app1"
    propagate_at_launch = true
  }
}

# Auto Scaling Group for App2
resource "aws_autoscaling_group" "app2" {
  name                      = "${var.environment}-app2-asg"
  vpc_zone_identifier       = var.subnet_ids
  desired_capacity          = 2
  min_size                  = 1
  max_size                  = 4
  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app2.id
    version = "$Latest"
  }

  target_group_arns = [var.target_group_arns[1]]

  tag {
    key                 = "Name"
    value               = "${var.environment}-app2-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "App"
    value               = "app2"
    propagate_at_launch = true
  }
}

# Scaling Policies
resource "aws_autoscaling_policy" "app1_scale_up" {
  name                   = "${var.environment}-app1-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app1.name
}

resource "aws_autoscaling_policy" "app1_scale_down" {
  name                   = "${var.environment}-app1-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app1.name
}

resource "aws_autoscaling_policy" "app2_scale_up" {
  name                   = "${var.environment}-app2-scale-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app2.name
}

resource "aws_autoscaling_policy" "app2_scale_down" {
  name                   = "${var.environment}-app2-scale-down"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app2.name
}

# CloudWatch Alarm for App1 CPU
resource "aws_cloudwatch_metric_alarm" "app1_high_cpu" {
  alarm_name          = "${var.environment}-app1-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app1.name
  }

  alarm_actions = [aws_autoscaling_policy.app1_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "app1_low_cpu" {
  alarm_name          = "${var.environment}-app1-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app1.name
  }

  alarm_actions = [aws_autoscaling_policy.app1_scale_down.arn]
}

# CloudWatch Alarm for App2 CPU
resource "aws_cloudwatch_metric_alarm" "app2_high_cpu" {
  alarm_name          = "${var.environment}-app2-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app2.name
  }

  alarm_actions = [aws_autoscaling_policy.app2_scale_up.arn]
}

resource "aws_cloudwatch_metric_alarm" "app2_low_cpu" {
  alarm_name          = "${var.environment}-app2-low-cpu"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app2.name
  }

  alarm_actions = [aws_autoscaling_policy.app2_scale_down.arn]
}

# Outputs
output "app_asg_name" {
  value = aws_autoscaling_group.app1.name
}

output "app1_asg_name" {
  value = aws_autoscaling_group.app1.name
}

output "app2_asg_name" {
  value = aws_autoscaling_group.app2.name
}

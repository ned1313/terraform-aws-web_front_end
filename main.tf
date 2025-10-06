# Security Groups
resource "aws_security_group" "nlb_sg" {
  name_prefix = "${var.prefix}-nlb-sg-"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.prefix}-${var.environment}-nlb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "ec2_sg" {
  name_prefix = "${var.prefix}-ec2-sg-"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow HTTP traffic from NLB"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.prefix}-${var.environment}-ec2-sg"
    Environment = var.environment
  }
}

## Autoscale group
resource "aws_launch_template" "front_end" {
  name_prefix   = "${var.prefix}-web-"
  image_id      = var.launch_template_ami
  instance_type = var.instance_type
  user_data     = var.user_data_contents

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = merge({
      Name        = "${var.prefix}-${var.environment}-ec2-instance"
      Environment = var.environment
    }, var.instance_tags)
  }
}

resource "aws_autoscaling_group" "front_end" {
  vpc_zone_identifier = var.public_subnet_ids
  desired_capacity    = var.autoscale_group_size
  max_size            = var.autoscale_group_min_max.max
  min_size            = var.autoscale_group_min_max.min

  launch_template {
    id      = aws_launch_template.front_end.id
    version = "$Latest"
  }

  health_check_type = "ELB"

  tag {
    key                 = "Name"
    value               = "${var.prefix}-${var.environment}-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = false
  }
}

# Load balancer resources
resource "aws_lb" "front_end" {
  name               = "${var.prefix}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.public_subnet_ids
  security_groups    = [aws_security_group.nlb_sg.id]

  enable_deletion_protection = false

  tags = {
    Environment = var.environment
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.front_end.arn
  port              = var.app_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.front_end.arn
  }
}

resource "aws_lb_target_group" "front_end" {
  name     = "${var.prefix}-lb-tg"
  port     = var.app_port
  protocol = "TCP"
  vpc_id   = var.vpc_id
}

# Create a new ALB Target Group attachment
resource "aws_autoscaling_attachment" "front_end" {
  autoscaling_group_name = aws_autoscaling_group.front_end.id
  lb_target_group_arn    = aws_lb_target_group.front_end.arn
}


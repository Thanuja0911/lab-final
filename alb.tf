#WAF
resource "aws_wafregional_sql_injection_match_set" "sql_injection_protection" {
  name = "sql-injection-protection"

  sql_injection_match_tuple {
    field_to_match {
      type = "QUERY_STRING"
    }
    text_transformation = "URL_DECODE"
  }
}

resource "aws_wafregional_rule" "injection_protection" {
  name        = "injection-protection"
  metric_name = "InjectionProtectionRule"

  predicate {
    type      = "SqlInjectionMatch"
    data_id   = aws_wafregional_sql_injection_match_set.sql_injection_protection.id
    negated   = false
  }
}

resource "aws_wafregional_web_acl" "web_acl" {
  name        = "web-acl"
  metric_name = "webACL"

  default_action {
    type = "ALLOW"
  }

  rule {
    action {
      type = "BLOCK"
    }
    priority = 1
    rule_id  = aws_wafregional_rule.injection_protection.id
  }
}


# Application Load Balancer (ALB)
resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = {
    Name = "app-lb"
  }
}

# Listener for ALB (HTTP on Port 80)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Target Group for React Web App Instances
resource "aws_lb_target_group" "app_tg" {
  name        = "app-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "app-target-group"
  }
}
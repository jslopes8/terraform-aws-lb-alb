
# ELBv2 - Application Load Balance
resource "aws_lb" "lb" {
  name                = var.name
  internal            = var.internal
  load_balancer_type  = var.load_balancer_type
  security_groups     = var.security_groups
  subnets             = var.subnets

  enable_deletion_protection = var.enable_deletion_protection

  dynamic "access_logs" {
    for_each  = length(keys(var.access_logs)) == 0 ? [] : [var.access_logs]
    content {
      bucket  = lookup(access_logs.value, "bucket", null)
      prefix  = lookup(access_logs.value, "prefix", null)
      enabled = lookup(access_logs.value, "enabled", null)
    }
  }

  dynamic "subnet_mapping" {
    for_each  = var.subnet_mapping
    content {
      subnet_id     = lookup(subnet_mapping.value, "subnet_id", null)
      allocation_id = lookup(subnet_mapping.value, "allocation_id", null)
    }
  }

  tags          = var.default_tags
}

############
# Listener #
############

resource "aws_alb_listener" "https_listeners" {
  count = var.create_lb ? length(var.https_listeners) : 0

  load_balancer_arn = aws_lb.lb.arn

  port            = var.https_listeners[count.index]["port"]
  protocol        = lookup(var.https_listeners[count.index], "protocol", "HTTPS")
  certificate_arn = var.https_listeners[count.index]["certificate_arn"]
  ssl_policy      = lookup(var.https_listeners[count.index], "ssl_policy", var.listener_ssl_policy_default)

  default_action {
    target_group_arn = var.https_listeners[count.index]["target_group_arn"]
    type             = "forward"
  }
}


resource "aws_alb_listener" "http_listeners" {
  count = var.create_lb ? length(var.http_listeners) : 0

  load_balancer_arn = aws_lb.lb.arn

  port            = var.http_listeners[count.index]["port"]
  protocol        = lookup(var.http_listeners[count.index], "protocol", "HTTP")

  default_action {
    target_group_arn = var.http_listeners[count.index]["target_group_arn"]
    type             = "forward"
  }
}

#################
# Listener Rule #
################

resource "aws_lb_listener_rule" "lb_https" {
  count = var.create_lb ? length(var.https_listeners) : 0
    
  listener_arn  = aws_lb_listener.lb.0.arn
  priority      = lookup(var.https_listeners[count.index], "priority_rule", null)

  dynamic "action" {
    for_each = length(keys(lookup(var.https_listeners[count.index], "redirect_rule", {}))) == 0 ? [] : [lookup(var.https_listeners[count.index], "redirect_rule", {})]
    content {
      type    = lookup(action.value, "type", null)

      dynamic "redirect" {
        for_each = length(keys(lookup(action.value, "redirect", {}))) == 0 ? [] : [lookup(action.value, "redirect", {})]
        content {
            port        = lookup(redirect.value, "type", "443")
            protocol    = lookup(redirect.value, "protocol", "HTTPS")
            status_code = lookup(redirect.value, "status_code", "HTTP_301")
        }
      }

    }
  }

  dynamic "action" {
    for_each = length(keys(lookup(var.https_listeners[count.index], "forward_rule", {}))) == 0 ? [] : [lookup(var.https_listeners[count.index], "forward_rule", {})]
    content {
      type              = lookup(action.value, "type", null)
      target_group_arn  = lookup(action.value, "target_group_arn", null)
    }
  }

  dynamic "condition" {
    for_each = length(keys(lookup(var.https_listeners[count.index], "condition", {}))) == 0 ? [] : [lookup(var.https_listeners[count.index], "condition", {})]
    content {
      dynamic "path_pattern" {
        for_each = length(keys(lookup(condition.value, "path_pattern", {}))) == 0 ? [] : [lookup(condition.value, "path_pattern", {})]
        content {
          values = lookup(path_pattern.value, "values", null)
        }
      }
    }
  }
}
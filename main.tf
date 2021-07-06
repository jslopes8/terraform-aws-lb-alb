###############################################################################################################3
#
# ELBv2 - Application Load Balance /Network Load Balance
#

resource "aws_lb" "main" {
  count = var.create ? 1 : 0

  # General Options
  name                = var.name
  internal            = var.internal
  load_balancer_type  = var.load_balancer_type
  security_groups     = var.security_groups
  subnets             = var.subnets

  # If true, deletion of the load balancer will be disabled via the AWS API.
  # Defaults to false
  enable_deletion_protection = var.enable_deletion_protection

  # An Access Logs block.
  dynamic "access_logs" {
    for_each  = length(keys(var.access_logs)) == 0 ? [] : [var.access_logs]
    
    # Access Logs support the following:
    content {
      bucket  = lookup(access_logs.value, "bucket", null)
      prefix  = lookup(access_logs.value, "prefix", null)
      enabled = lookup(access_logs.value, "enabled", null)
    }
  }

  # A subnet mapping block
  dynamic "subnet_mapping" {
    for_each  = var.subnet_mapping

    # Subnet Mapping blocks support the following:
    content {
      subnet_id             = lookup(subnet_mapping.value, "subnet_id", null)
      allocation_id         = lookup(subnet_mapping.value, "allocation_id", null)
      private_ipv4_address  = lookup(subnet_mapping.value, "private_ipv4", null)
      ipv6_address          = lookup(subnet_mapping.value, "ipv6_address", null)
    }
  }

  # A map of tags to assign to the resource.
  tags = var.default_tags
}

###################################################################################
#
# ALB Listener HTTP
#


resource "aws_lb_listener" "listeners" {
  count = var.create && var.load_balancer_type == "application" ? length(var.listeners) : 0

  # ARN of the load balancer.
  load_balancer_arn = aws_lb.main.0.arn

  # General Options
  port            = var.listeners[count.index]["port"]
  protocol        = lookup(var.listeners[count.index], "protocol", null)

  # Configuration block for default actions.
  default_action {
    target_group_arn = var.listeners[count.index]["target_group_arn"]
    type             = lookup(var.listeners[count.index], "type", null)
  }
}

resource "aws_lb_listener_rule" "listeners_rule" {
  count = var.create ? length(var.listeners_rule) : 0
    
  listener_arn  = aws_lb_listener.listeners.0.arn
  priority      = lookup(var.listeners_rule[count.index], "priority_rule", null)

  dynamic "action" {
    for_each = length(keys(lookup(var.listeners_rule[count.index], "action", []))) == 0 ? [] : [lookup(var.listeners_rule[count.index], "action", [])]
    
    content {
      type              = lookup(action.value, "type", null)
      target_group_arn  = lookup(action.value, "target_group_arn", null)

      dynamic "redirect" {
        for_each = lookup(action.value, "redirect", [])

        content {
            port        = lookup(redirect.value, "port", "443")
            protocol    = lookup(redirect.value, "protocol", "HTTPS")
            status_code = lookup(redirect.value, "status_code", "HTTP_301")
        }
      }

      dynamic "forward" {
        for_each = lookup(action.value, "forward", [])

        content {
          dynamic "stickiness" {
            for_each = lookup(forward.value, "stickiness", [])

            content {
              enabled   = lookup(stickiness.value, "enabled", null)
              duration  = lookup(stickiness.value, "duration", null)
            }
          }
          dynamic "target_group" {
            for_each = lookup(forward.value, "target_group", [])

            content {
              arn     = lookup(target_group.value, "target_group_arn", null)
              weight  = lookup(target_group.value, "weight", null)

            }
          }
        }
      }
    }
  }

  dynamic "condition" {
    for_each = length(keys(lookup(var.listeners_rule[count.index], "condition", []))) == 0 ? [] : [lookup(var.listeners_rule[count.index], "condition", [])]

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
##################################################################################
#
# ALB Listener HTTPS
#

#resource "aws_lb_listener" "https_listeners" {
#  count = var.create_lb ? length(var.https_listeners) : 0
#
#  # ARN of the load balancer.
#  load_balancer_arn = aws_lb.main.0.arn
#
#  # General Options
#  port            = var.https_listeners[count.index]["port"]
#  protocol        = lookup(var.https_listeners[count.index], "protocol", "HTTPS")
#  certificate_arn = var.https_listeners[count.index]["certificate_arn"]
#  ssl_policy      = lookup(var.https_listeners[count.index], "ssl_policy", var.listener_ssl_policy_default)
#
#  # Configuration block for default actions.
#  default_action {
#    target_group_arn = var.https_listeners[count.index]["target_group_arn"]
#    type             = "forward"
#  }
#}
#
##
## ALB Listener HTTPS Rule - Redirect Rule and Forward Rule
##
#
#resource "aws_lb_listener_rule" "https_listeners" {
#  count = var.create_lb ? length(var.https_listeners) : 0
#    
#  listener_arn  = aws_lb_listener.https_listeners.0.arn
#  priority      = lookup(var.https_listeners[count.index], "priority_rule", null)
#
#  dynamic "action" {
#    for_each = length(keys(lookup(var.https_listeners[count.index], "redirect_rule", {}))) == 0 ? [] : [lookup(var.https_listeners[count.index], "redirect_rule", {})]
#    content {
#      type    = lookup(action.value, "type", null)
#
#      dynamic "redirect" {
#        for_each = length(keys(lookup(action.value, "redirect", {}))) == 0 ? [] : [lookup(action.value, "redirect", {})]
#
#        content {
#            port        = lookup(redirect.value, "port", "443")
#            protocol    = lookup(redirect.value, "protocol", "HTTPS")
#            status_code = lookup(redirect.value, "status_code", "HTTP_301")
#        }
#      }
#    }
#  }
#
#  dynamic "action" {
#    for_each = length(keys(lookup(var.https_listeners[count.index], "forward_rule", {}))) == 0 ? [] : [lookup(var.https_listeners[count.index], "forward_rule", {})]
#
#    content {
#      type              = lookup(action.value, "type", null)
#      target_group_arn  = lookup(action.value, "target_group_arn", null)
#    }
#  }
#
#  dynamic "condition" {
#    for_each = length(keys(lookup(var.https_listeners[count.index], "condition", {}))) == 0 ? [] : [lookup(var.https_listeners[count.index], "condition", {})]
#
#    content {
#      dynamic "path_pattern" {
#        for_each = length(keys(lookup(condition.value, "path_pattern", {}))) == 0 ? [] : [lookup(condition.value, "path_pattern", {})]
#
#        content {
#          values = lookup(path_pattern.value, "values", null)
#        }
#      }
#    }
#  }
#}
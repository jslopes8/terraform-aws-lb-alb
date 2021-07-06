# Terraform Module Application Load Balance

## Usage
```bash
module "alb_jenkins_https" {
  source = "git::https://github.com/jslopes8/terraform-aws-lb-alb.git?ref=v2.0"

  name                        = "alb-${local.stack_name}"
  internal                    = "false"
  load_balancer_type          = "application"
  enable_deletion_protection  =  "false"

  subnets         = [ 
    tolist(data.aws_subnet_ids.sn_public.ids)[0],
    tolist(data.aws_subnet_ids.sn_public.ids)[1],
  ]
  security_groups = [ module.alb_jenkins_sg.id ]

  listeners = [{
    port              = "8080"
    protocol          = "HTTP"
    target_group_arn  = module.tg_jenkins_master.id
    type              = "forward"
  }]

  listeners_rule = [{
    priority_rule = "1"
    action = {
      target_group_arn = module.tg_jenkins_master.id
      type              = "redirect"
      redirect = [{
        port        = "80"
        protocol    = "HTTP"
        status_code = "HTTP_301"
      }]
    }
    condition = {
      path_pattern = {
        values = ["/login"]
      }
    }
  }]

  default_tags = local.default_tags 
}
```
## Requirements

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Variables Inputs
| Name | Description | Required | Type | Default |
| ---- | ----------- | -------- | ---- | ------- |

## Variable Outputs
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
| Name | Description |
| ---- | ----------- |

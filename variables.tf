variable "create_lb" {
    type    = bool
    default = true
}
variable "name" {
    type    = string
}
variable "internal" {
    type    = bool
}
variable "load_balancer_type" {
    type    = string
    default = "application"
}
variable "security_groups" {
    type    = list(string)
    default = []
}
variable "subnets" {
    type    = list(string)
    default = []
}
variable "enable_deletion_protection" {
    type    = bool
}
variable "access_logs" {
    type    = map(string)
    default = {}
}
variable "default_tags" {
    type    = map(string)
    default = {}
}
variable "action" {
    type    = list(map(string))
    default = []
}
variable "subnet_mapping" {
    type    = list(map(string))
    default = []
}
variable "condition" {
    type    = list(map(string))
    default = []
}
variable "priority" {
    type    = number
}
variable "https_listeners" {
    type    = list(map(string))
    default = []
}
variable "http_listeners" {
    type    = list(map(string))
    default = []
}
variable "listener_ssl_policy_default" {
    type    = string
    default = "ELBSecurityPolicy-2016-08"
}

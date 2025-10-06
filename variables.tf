variable "app_port" {
  type        = number
  description = "Port the application listens on"
  default     = 80
}

variable "autoscale_group_min_max" {
  type = object({
    min = number
    max = number
  })

  description = "The minimum and maximum size for the autoscale group."
}

variable "autoscale_group_size" {
  type        = number
  description = "Default size of autoscale group."
}

variable "environment" {
  type        = string
  description = "(Required) Environment of all resources"
}

variable "instance_tags" {
  type = map(string)
  description = "Additional tags for the launch template instances"
  default = {}
}

variable "instance_type" {
  type        = string
  description = "Instance type for Autoscale group"
  default     = "t3.micro"
}

variable "launch_template_ami" {
  type        = string
  description = "AMI ID to use for the launch template"
}

variable "prefix" {
  type        = string
  description = "(Required) Prefix to use for all resources in this module."
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs for the autoscale group and NLB."
}

variable "user_data_contents" {
  type        = string
  description = "User data script contents for the launch template."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where resources will be deployed."
}
variable "service_name" {
  description = "Service name"
  type        = "string"
}

variable "workspace" {
  description = "terraform workspace"
  type        = "string"
}

variable "aws_account_id" {
  description = "aws_account_id"
  type        = "string"
}

variable "region" {
  description = "region"
  type        = "string"
}

variable "apigw_method" {
  description = "apigw_method"
  type        = "string"
}

variable "s3_buffer_size" {
  description = "s3_buffer_size"
  type        = "string"
}

variable "s3_buffer_interval" {
  description = "s3_buffer_interval"
  type        = "string"
}

variable "columns" {
  description = "columns"
  type        = "map"
}
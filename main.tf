module "data_pipeline" {
  source = "./modules/data-pipeline"

  workspace      = "dev"
  aws_account_id = "1111111111111"
  region         = "${var.region}"
  service_name = "testservice"

  // api gateway method
  apigw_method = "POST"

  // kinesis firehose option
  s3_buffer_size = 5
  s3_buffer_interval = 300

  // glue table patition
  columns = {
    id = "int"
    type = "string"
    status = "int"
    created_at = "timestamp"
  }
}

variable "region" {
  default = "us-east-1"
}

provider "aws" {
  access_key = ""
  secret_key = ""
  region     = "${var.region}"
}
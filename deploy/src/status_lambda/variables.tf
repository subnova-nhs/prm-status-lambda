variable "aws_region" {
  description = "The region in which the infrastructure will be deployed"
}

variable "environment" {
  description = "The name of the environment being deployed"
}

variable "lambda_zip" {
  description = "The path, relative to this module, to the ZIP file that contains the built lambda"
}

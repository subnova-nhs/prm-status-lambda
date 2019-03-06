module "apigw_setup" {
  source = "github.com/subnova-nhs/prm-apigw-setup/deploy/src//modules/apigw_setup"

  aws_region = "${var.aws_region}"
  environment = "${var.environment}"
}
module "apigw_deploy" {
  source = "github.com/subnova-nhs/prm-apigw-deploy/deploy/src//modules/apigw_deploy"

  aws_region = "${var.aws_region}"
  environment = "${var.environment}"
}
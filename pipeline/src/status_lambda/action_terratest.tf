resource "aws_codebuild_project" "terratest" {
  name        = "prm-status-lambda-terratest-${var.environment}"
  description = "Test the status lambda deploy"

  source {
    type      = "CODEPIPELINE"
    buildspec = "./pipeline/src/status_lambda/action_terratest.yml"
  }

  artifacts {
    type = "CODEPIPELINE"
  }

  service_role = "${var.iam_role}"

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/codebuild/terratest:latest"
    type         = "LINUX_CONTAINER"

    environment_variable {
      name  = "ENVIRONMENT"
      value = "${var.environment}"
    }
  }

  tags {
    Environment = "${var.environment}"
  }
}

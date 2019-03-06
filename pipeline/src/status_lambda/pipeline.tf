resource "aws_s3_bucket" "artifacts" {
  bucket = "prm-${data.aws_caller_identity.current.account_id}-status-lambda-pipeline-artifacts-${var.environment}"
  acl    = "private"

  versioning {
    enabled = true
  }
}

# Role to use for running pipeline
data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipeline_role" {
  name               = "prm-status-lambda-pipeline-${var.environment}"
  assume_role_policy = "${data.aws_iam_policy_document.codepipeline_assume.json}"
}

data "aws_iam_policy_document" "pipeline_role_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:DeleteObject*",
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:*",
    ]

    resources = [
      "arn:aws:s3:::prm-${data.aws_caller_identity.current.account_id}-apigw-setup-pipeline-artifacts-${var.environment}/*",
      "${aws_s3_bucket.artifacts.arn}/*"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketVersioning",
    ]

    resources = [
      "arn:aws:s3:::prm-${data.aws_caller_identity.current.account_id}-apigw-setup-pipeline-artifacts-${var.environment}",
      "${aws_s3_bucket.artifacts.arn}"
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
    ]

    resources = [
      "${aws_codebuild_project.test.arn}",
      "${aws_codebuild_project.build.arn}",
      "${aws_codebuild_project.terratest.arn}",
      "${aws_codebuild_project.deploy.arn}",
    ]
  }
}

resource "aws_iam_role_policy" "pipeline_role_policy" {
  name   = "prm-status-lambda-pipeline"
  role   = "${aws_iam_role.pipeline_role.id}"
  policy = "${data.aws_iam_policy_document.pipeline_role_policy.json}"
}

# Pipeline
data "aws_ssm_parameter" "github_token" {
  name = "${var.github_token_name}"
}

resource "aws_codepipeline" "pipeline" {
  name     = "prm-status-lambda-${var.environment}"
  role_arn = "${aws_iam_role.pipeline_role.arn}"

  artifact_store {
    location = "${aws_s3_bucket.artifacts.bucket}"
    type     = "S3"
  }

  stage {
    name = "source"

    action {
      name             = "source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source"]
      run_order        = 1

      configuration {
        Owner      = "subnova-nhs"
        Repo       = "prm-status-lambda"
        Branch     = "master"
        OAuthToken = "${data.aws_ssm_parameter.github_token.value}"
      }
    }

    action {
      name             = "apigw_setup"
      category         = "Source"
      owner            = "AWS"
      provider         = "S3"
      version          = "1"
      output_artifacts = ["apigw_setup"]
      run_order        = 1

      configuration {
        S3Bucket = "prm-${data.aws_caller_identity.current.account_id}-apigw-setup-pipeline-artifacts-${var.environment}"
        S3ObjectKey = "prm-apigw-setup-${var.environment}/outputs/output.json"     
      }
    }
  }

  stage {
    name = "test"

    action {
      name            = "test"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source"]
      run_order       = 1

      configuration {
        ProjectName = "${aws_codebuild_project.test.name}"
        PrimarySource = "source"
      }
    }
  }

  stage {
    name = "build"

    action {
      name            = "build"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source"]
      output_artifacts = ["build"]
      run_order       = 1

      configuration {
        ProjectName = "${aws_codebuild_project.build.name}"
        PrimarySource = "source"
      }
    }
  }

  stage {
    name = "terratest"

    action {
      name            = "terratest"
      category        = "Test"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source", "build"]
      run_order       = 1

      configuration {
        ProjectName = "${aws_codebuild_project.terratest.name}"
        PrimarySource = "source"
      }
    }
  }

  stage {
    name = "deploy"

    action {
      name            = "deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      version         = "1"
      input_artifacts = ["source", "build"]
      output_artifacts = ["terraform"]

      configuration {
        ProjectName = "${aws_codebuild_project.deploy.name}"
        PrimarySource = "source"
      }
    }
  }

  stage {
    name = "notify"

    action {
      name = "notify"
      category = "Deploy"
      owner = "AWS"
      provider = "S3"
      version = "1"
      input_artifacts = ["terraform"]

      configuration {
        BucketName = "${aws_s3_bucket.artifacts.bucket}"
        Extract = "true"
        ObjectKey = "prm-status-lambda-${var.environment}/outputs"
      }
    }
  }
}


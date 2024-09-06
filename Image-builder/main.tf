# Fetch default VPC
data "aws_vpc" "default" {
  default = true
}

# Fetch the subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# S3 bucket for logs
resource "aws_s3_bucket" "imagebuilder_logs" {
  bucket = "${var.name_prefix}-imagebuilder-logs-234"
}

resource "aws_imagebuilder_component" "chrome_notepad_install" {

  name     = "${var.name_prefix}-chrome_notepad_install"
  platform = var.platform
  version  = var.version
  description = var.description
  change_description = var.change_description

  data = yamlencode({
    schemaVersion = 1.0
    phases = [{
      name = "Install Software"
      steps = [{
        action = "ExecutePowerShell"
        name      = "InstallGoogleChrome"
        onFailure = "Abort"
        maxAttempts = "3"
        inputs = {
          commands = [
            "Invoke-WebRequest -Uri ${var.chrome_url} -OutFile C:\\Install\\chrome_installer.exe",
            "Start-Process msiexec.exe -ArgumentList '/i C:\\Install\\chrome_installer.exe /quiet /norestart' -Wait"
          ]
        }
        action = "ExecutePowerShell"
        name      = "InstallNotepad++"
        onFailure = "Abort"
        maxAttempts = "3"
        inputs = {
          commands = [
            "Invoke-WebRequest -Uri ${var.notepad_url} -OutFile C:\\Install\\notepadpp.exe",
            "Start-Process C:\\Install\\notepadpp.exe -ArgumentList '/S' -Wait"
          ]
        }
      }]
    }]
  })

  tags = {
    Environment = var.environment
    Name = "${var.name_prefix}-aws_imagebuilder_component-${var.environment}"
    version = var.version
  }
}

# EC2 Image Builder Recipe
resource "aws_imagebuilder_image_recipe" "windows_recipe" {
    name = "${var.name_prefix}-Windows-Recipe"
    version = var.version
    parent_image = var.parent_image_arn

    component {
        component_arn = aws_imagebuilder_component.chrome_notepad_install.arn
    }

    block_device_mapping {
      device_name = "/dev/sda1"
      ebs {
        delete_on_termination = true
        volume_size = 100
        volume_type = "gp2"
      }
    }
}

# EC2 Image Builder Infrastructure Configuration
resource "aws_imagebuilder_infrastructure_configuration" "infra_config" {
  description                   = "Image builder Infrastructure"
  instance_profile_name         = aws_iam_instance_profile.imagebuilder_profile.name
  instance_types                = var.instance_types
  name                          = "${var.name_prefix}-ImageBuilderInfraConfig"
  security_group_ids            = [aws_security_group.imagebuilder_sg.id]
  sns_topic_arn                 = aws_sns_topic.imagebuilder_notifications.arn
  subnet_id                     = data.aws_subnets.default.ids[0]
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = aws_s3_bucket.imagebuilder_logs.bucket
      s3_key_prefix  = "logs"
    }
  }

  tags = {
    Environment = var.environment
    Name = "${var.name_prefix}-aws_imagebuilder_infrastructure_configuration-${var.environment}"
    version = var.version
  }
}

# Security Group
resource "aws_security_group" "imagebuilder_sg" {
  name = "${var.name_prefix}-ImageBuilderSG"
  vpc_id = data.aws_vpc.default

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_imagebuilder_image_pipeline" "image_pipeline" {
  name                             = "${var.name_prefix}-Windows-Golden-AMI-Pipeline"

  image_recipe_arn                 = aws_imagebuilder_image_recipe.windows_recipe.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.infra_config.arn

  schedule {
    schedule_expression = "cron(0 0 * * ? *)"
  }

  tags = {
    Environment = var.environment
    Name = "${var.name_prefix}-aws_imagebuilder_image_pipeline-${var.environment}"
    version = var.version
  }
  
}

# SNS Topic for Notifications
resource "aws_sns_topic" "imagebuilder_notifications" {
  name = "${var.name_prefix}-ImageBuilderNotifications"
}

resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.imagebuilder_notifications.arn
  protocol  = "email"
  endpoint  = "ogunleyedamola1995@yahoo.com"
}

# IAM Instance Profile for EC2 Instances in Image Builder
resource "aws_iam_instance_profile" "imagebuilder_profile" {
  name = "${var.name_prefix}-ImageBuilderInstanceProfile"
  role = aws_iam_role.imagebuilder_role.name
}

# IAM Role for EC2 Instance Profile
resource "aws_iam_role" "imagebuilder_role" {
  name = "${var.name_prefix}-ImageBuilderRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "imagebuilder_policy_attachment" {
  role       = aws_iam_role.imagebuilder_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# IAM Policy for allowing Image Builder to log to S3
resource "aws_iam_policy" "imagebuilder_s3_policy" {
  name = "${var.name_prefix}-ImageBuilderS3Policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = [
        "s3:PutObject",
        "s3:GetBucketLocation",
        "s3:ListBucket",
        "s3:GetObject"
      ],
      Resource = [
        aws_s3_bucket.imagebuilder_logs.arn,
        "${aws_s3_bucket.imagebuilder_logs.arn}/*"
      ]
    }]
  })
}

# Attach S3 logging policy to the Image Builder Role
resource "aws_iam_role_policy_attachment" "imagebuilder_s3_policy_attachment" {
  role       = aws_iam_role.imagebuilder_role.name
  policy_arn = aws_iam_policy.imagebuilder_s3_policy.arn
}

# Permissions to allow Image Builder to publish to SNS topic
resource "aws_sns_topic_policy" "sns_policy" {
  arn = aws_sns_topic.imagebuilder_notifications.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = {
        Service = "imagebuilder.amazonaws.com"
      }
      Action    = "sns:Publish"
      Resource  = aws_sns_topic.imagebuilder_notifications.arn
    }]
  })
}
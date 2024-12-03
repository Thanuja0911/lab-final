resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for EC2 Permissions
resource "aws_iam_policy" "ec2_instance_policy" {
  name        = "ec2-instance-policy"
  description = "Policy for EC2 instance to access AWS services"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:*",              # Full access to S3 buckets
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents", # Logging to CloudWatch
          "ec2:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the IAM Policy to the Role
resource "aws_iam_role_policy_attachment" "ec2_instance_policy_attachment" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = aws_iam_policy.ec2_instance_policy.arn
}

# IAM Instance Profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_role" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}

# Launch Template for React Web App
resource "aws_launch_template" "web_app" {
  name          = "web-app-launch-template"
  image_id      = "ami-0d53d72369335a9d6"  # Replace with your actual AMI ID
  instance_type = "t2.micro"

  # Network configuration with security group
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  # User data for setting up the React web app
  user_data = base64encode(file("${path.module}/install_backend.sh"))
}

# Auto Scaling Group for React Web App
resource "aws_autoscaling_group" "web_app_asg" {
  desired_capacity     = 2
  max_size             = 3
  min_size             = 1
  vpc_zone_identifier  = [module.vpc.public_subnets[0], module.vpc.public_subnets[1]]  # Subnets from Multiple AZs

  # Attach the launch template
  launch_template {
    id      = aws_launch_template.web_app.id
    version = "$Latest"
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "React-Web-App-ASG"
    propagate_at_launch = true
  }
}

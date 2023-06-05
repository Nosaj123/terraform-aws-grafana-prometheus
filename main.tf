provider "aws" {
  region = var.aws_region
}

# Define the userdata template file
data "template_file" "userdata" {
  template = file("${path.module}/userdata.tpl")
}


resource "aws_launch_configuration" "launch_config" {
  name             = "Dev-ASG-Config"
  image_id         = var.image_id
  instance_type    = var.aws_instance_type
  key_name         = var.pem_key
  security_groups  = [aws_security_group.sg.id]
  user_data_base64 = base64encode(data.template_file.userdata.rendered) # Encode userdata as base64


}

resource "aws_autoscaling_group" "asg" {
  availability_zones   = ["us-east-1a"]
  name                 = "Dev-ASG"
  min_size             = var.minimum_instance
  max_size             = var.maximum_instance
  desired_capacity     = var.desired_instance
  launch_configuration = aws_launch_configuration.launch_config.name
  force_delete         = true

  tag {
    key                 = "Environment"
    value               = "Dev"
    propagate_at_launch = true
  }
  tag {
    key                 = "Terraform"
    value               = "True"
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_policy" "asg_policy" {
  name                   = "Dev-ASG-Policy"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 100.0
  }
}

data "aws_autoscaling_group" "asg_data" {
  name = aws_autoscaling_group.asg.name
}


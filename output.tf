# Output the public IP address of the first EC2 instance in the ASG
output "instance_ips" {
  value = data.aws_autoscaling_group.asg_data.name[*]
}




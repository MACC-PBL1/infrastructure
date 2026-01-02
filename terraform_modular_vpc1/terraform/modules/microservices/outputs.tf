output "asg_names" { value = { for k, asg in aws_autoscaling_group.ms : k => asg.name } }

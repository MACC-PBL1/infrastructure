output "private_ips" {
  description = "Map of instance names to private IPs"
  value       = { for k, v in aws_instance.services : k => v.private_ip }
}

output "instance_ids" {
  description = "Map of instance names to instance IDs"
  value       = { for k, v in aws_instance.services : k => v.id }
}

output "instances_info" {
  description = "Complete information about instances"
  value = {
    for k, v in aws_instance.services : k => {
      id         = v.id
      private_ip = v.private_ip
      az         = v.availability_zone
      subnet_id  = v.subnet_id
    }
  }
}
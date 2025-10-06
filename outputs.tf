output "autoscaling_group_name" {
  description = "The name of the autoscaling group"
  value       = aws_autoscaling_group.front_end.name
}

output "lb_public_dns" {
  description = "The public DNS name of the load balancer"
  value       = aws_lb.front_end.dns_name
}
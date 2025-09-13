output "cluster_name" {
  value = aws_ecs_cluster.cluster.name
}

output "service_name" {
  value = aws_ecs_service.service.name
}

output "log_group" {
  value = aws_cloudwatch_log_group.ecs.name
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_id_1" {
  description = "The ID of the first Public Subnet"
  value       = aws_subnet.public_subnet_1.id
}

output "public_subnet_id_2" {
  description = "The ID of the second Public Subnet"
  value       = aws_subnet.public_subnet_2.id
}

output "private_subnet_id" {
  description = "The ID of the Private Subnet"
  value       = aws_subnet.private_subnet.id
}

output "ecs_cluster_name" {
  description = "The name of the ECS Cluster"
  value       = aws_ecs_cluster.ecs_cluster.name
}

output "ecs_service_name" {
  description = "The name of the ECS Service"
  value       = aws_ecs_service.fargate_service_1.name
}

// Creating an output for the Application Load Balancer DNS name
output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer"
  value       = aws_lb.app_lb.dns_name  // Output the DNS name of the ALB
}

// Output the EFS file system ID
output "efs_file_system_id" {
  value = aws_efs_file_system.efs.id  // Output the ID of the EFS file system
}
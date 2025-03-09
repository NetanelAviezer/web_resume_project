output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.linux_docker.public_ip
}

output "rds_endpoint" {
  description = "Endpoint of the RDS instance"
  value       = aws_db_instance.default.endpoint
}
output "frontend_public_ip" {
  description = "Public IP of frontend EC2"
  value       = aws_instance.frontend.public_ip
}

output "frontend_private_ip" {
  description = "Private IP of frontend EC2"
  value       = aws_instance.frontend.private_ip
}

output "backend_private_ip" {
  description = "Private IP of backend EC2"
  value       = aws_instance.backend.private_ip
}

output "db_private_ip" {
  description = "Private IP of database EC2"
  value       = aws_instance.db.private_ip
}

output "alb_dns" {
  value = aws_lb.app_alb.dns_name
}

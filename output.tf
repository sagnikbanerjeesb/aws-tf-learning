// Publicly available DNS Name of the ALB
output "alb-public-dns" {
  value = aws_lb.public-alb.dns_name
}
output "ip_publica_servidor" {
  description = "La dirección IP pública de nuestro nuevo servidor web"
  value       = aws_instance.mi_servidor_web.public_ip
}
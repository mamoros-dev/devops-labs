output "url_servidor_web" {
  description = "Dirección URL para acceder a la aplicación desde el navegador"
  value       = "http://${aws_instance.servidor_web_app.public_ip}"
}

output "vpc_id_creada" {
  description = "ID de la VPC propia creada en AWS"
  value       = aws_vpc.vpc_produccion.id
}

output "security_group_id" {
  description = "ID del Security Group asociado"
  value       = aws_security_group.sg_web.id
}
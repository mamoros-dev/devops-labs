# 1. Indicamos el proveedor y la región de AWS (Virginia)
provider "aws" {
  region = "us-east-1"
}

# 2. Definimos el servidor EC2 con el script de automatización
resource "aws_instance" "mi_servidor_web" {
  ami           = "ami-0c7217cdde317cfec" # ID de Ubuntu 22.04 LTS en us-east-1
  instance_type = "t3.micro"             # Tipo de instancia seguro dentro de tus créditos/capa gratuita

  # 🚀 Script automático de Bash al arrancar la máquina
  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update -y
              sudo apt-get install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              echo "<h1>¡Servidor de Miguel levantado con Terraform con éxito!</h1>" | sudo tee /var/www/html/index.html
              EOF

  tags = {
    Name = "servidor-web-nginx-miguel"
  }
}
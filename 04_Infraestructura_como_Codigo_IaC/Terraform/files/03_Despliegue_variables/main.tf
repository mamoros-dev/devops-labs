provider "aws" {
  region  = var.region_aws
  profile = "personal"
}

resource "aws_instance" "mi_servidor_web" {
  ami           = var.ami_id
  instance_type = var.tipo_instancia

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx
              echo "<meta charset='utf-8'><h1>¡Servidor Amazon Linux de Miguel con éxito!</h1>" | tee /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = var.nombre_servidor
  }
}
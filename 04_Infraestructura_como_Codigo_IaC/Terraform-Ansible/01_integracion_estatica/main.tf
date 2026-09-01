# 1. Indicamos a Terraform que trabaje con el proveedor de AWS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configuración del proveedor de AWS y región
provider "aws" {
  region  = "us-east-1"
  profile = "personal" # Usa tu perfil de AWS CLI
}

# 2. Subimos tu clave pública SSH a AWS
resource "aws_key_pair" "mi_clave_ssh" {
  key_name   = "clave-ansible-lab"
  public_key = file("~/.ssh/aws_ansible_key.pub")
}

# 3. Creamos el Grupo de Seguridad (Firewall)
resource "aws_security_group" "sg_web" {
  name        = "sg_ansible_lab"
  description = "Permitir SSH y HTTP"

  # Permitir tráfico SSH (puerto 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir tráfico HTTP (puerto 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permitir todo el tráfico saliente (necesario para descargar actualizaciones)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Buscamos la AMI oficial más reciente de Ubuntu 22.04 LTS
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # ID oficial de Canonical (creadores de Ubuntu)

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 5. Creamos la Instancia EC2
resource "aws_instance" "servidor_web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro" # Incluida en la capa gratuita / lab

  key_name               = aws_key_pair.mi_clave_ssh.key_name
  vpc_security_group_ids = [aws_security_group.sg_web.id]

  tags = {
    Name = "EC2-Ansible-Lab"
  }
}

# 6. Salida de datos (Outputs): Para ver la IP pública al terminar
output "ip_publica_servidor" {
  value       = aws_instance.servidor_web.public_ip
  description = "IP Pública asignada a la instancia EC2"
}

# 7. Generar el archivo de inventario para Ansible
resource "local_file" "inventario_ansible" {
  filename = "${path.module}/hosts.ini"

  content = <<EOF
[webservers]
${aws_instance.servidor_web.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/aws_ansible_key
EOF
}
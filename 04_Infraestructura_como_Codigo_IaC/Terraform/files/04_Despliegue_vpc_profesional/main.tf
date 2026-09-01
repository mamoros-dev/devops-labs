provider "aws" {
  region  = var.region_aws
  profile = "personal"
}

# 1️⃣ CREACIÓN DE LA VPC (Nuestra red aislada en la nube)
resource "aws_vpc" "vpc_produccion" {
  cidr_block           = var.cidr_vpc
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "vpc-miguel-${var.entorno}"
    Env  = var.entorno
  }
}

# 2️⃣ INTERNET GATEWAY (La puerta para que la VPC se comunique con Internet)
resource "aws_internet_gateway" "igw_produccion" {
  vpc_id = aws_vpc.vpc_produccion.id

  tags = {
    Name = "igw-miguel-${var.entorno}"
  }
}

# 3️⃣ SUBRED PÚBLICA (Donde residirán nuestros servidores accesibles desde fuera)
resource "aws_subnet" "subred_publica" {
  vpc_id                  = aws_vpc.vpc_produccion.id
  cidr_block              = var.cidr_subred_publica
  map_public_ip_on_launch = true # Asigna IP pública automáticamente a las máquinas

  tags = {
    Name = "subred-publica-miguel"
  }
}

# 4️⃣ TABLA DE ENRUTAMIENTO (Define que todo el tráfico 0.0.0.0/0 vaya al Internet Gateway)
resource "aws_route_table" "tabla_rutas_publica" {
  vpc_id = aws_vpc.vpc_produccion.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_produccion.id
  }

  tags = {
    Name = "rt-publica-miguel"
  }
}

# 5️⃣ ASOCIACIÓN (Conecta la subred pública con la tabla de enrutamiento)
resource "aws_route_table_association" "asociacion_publica" {
  subnet_id      = aws_subnet.subred_publica.id
  route_table_id = aws_route_table.tabla_rutas_publica.id
}

# 6️⃣ SECURITY GROUP (El Firewall a nivel de instancia: abre los puertos 80 y 22)
resource "aws_security_group" "sg_web" {
  name        = "sg_servidor_web_miguel"
  description = "Permitir trafico HTTP y SSH de entrada"
  vpc_id      = aws_vpc.vpc_produccion.id

  # Regla de Entrada: HTTP (Puerto 80) desde cualquier lugar
  ingress {
    description = "HTTP desde cualquier lugar"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de Entrada: SSH (Puerto 22) para administración
  ingress {
    description = "SSH de administracion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla de Salida: Permitir todo el tráfico de salida a Internet
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-web-miguel"
  }
}

# 7️⃣ BUSCADOR DINÁMICO DE AMI (Amazon Linux 2023)
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 8️⃣ INSTANCIA EC2 (El servidor web real montado DENTRO de nuestra VPC y Subred)
resource "aws_instance" "servidor_web_app" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.tipo_instancia
  subnet_id              = aws_subnet.subred_publica.id
  vpc_security_group_ids = [aws_security_group.sg_web.id]

  # User data para crear una aplicación Dashboard en tiempo de inicio
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y nginx
              systemctl start nginx
              systemctl enable nginx

              # Capturamos metadatos de la instancia mediante IMDSv2
              TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token-ttl-sec: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
              AVAIL_ZONE=$(curl -s -H "X-aws-ec2-metadata-token-ttl-sec: $TOKEN" http://169.254.169.254/latest/meta-data/placement/availability-zone)

              # Creamos una landing page visual profesional
              cat <<HTML > /usr/share/nginx/html/index.html
              <!DOCTYPE html>
              <html>
              <head>
                <style>
                  body { font-family: Arial, sans-serif; background-color: #f4f6f9; color: #333; text-align: center; padding-top: 50px; }
                  .card { background: white; max-width: 600px; margin: 0 auto; padding: 30px; border-radius: 12px; box-shadow: 0 4px 15px rgba(0,0,0,0.1); }
                  h1 { color: #ff9900; }
                  .badge { background: #232f3e; color: #fff; padding: 6px 12px; border-radius: 4px; font-weight: bold; }
                  .info { text-align: left; margin-top: 20px; font-size: 16px; line-height: 1.6; }
                </style>
              </head>
              <body>
                <div class="card">
                  <h1>🚀 AWS Production Workload</h1>
                  <p>Infraestructura desplegada dinámicamente con <strong>Terraform</strong> por Miguel.</p>
                  <hr>
                  <div class="info">
                    <p><strong>Estado del Servicio:</strong> <span class="badge" style="background:#28a745;">ONLINE</span></p>
                    <p><strong>VPC ID:</strong> <code>10.0.0.0/16 (Custom VPC)</code></p>
                    <p><strong>Instance ID:</strong> <code>'$INSTANCE_ID'</code></p>
                    <p><strong>Zona de Disponibilidad:</strong> <code>'$AVAIL_ZONE'</code></p>
                  </div>
                </div>
              </body>
              </html>
              HTML
              EOF

  tags = {
    Name = "servidor-app-${var.entorno}"
  }
}
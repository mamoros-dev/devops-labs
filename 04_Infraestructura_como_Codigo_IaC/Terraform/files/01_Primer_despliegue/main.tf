resource "aws_instance" "mi_primer_servidor" {
  ami           = "ami-0c7217cdde317cfec" # ID de la imagen de Ubuntu 22.04 LTS en us-east-1
  instance_type = "t3.micro"             # Tipo de máquina elegible en la Capa Gratuita (Free Tier)

  tags = {
    Name = "servidor-entrenamiento-miguel"
  }
}
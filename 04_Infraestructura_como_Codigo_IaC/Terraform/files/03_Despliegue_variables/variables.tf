variable "region_aws" {
  description = "Región de AWS donde desplegaremos la infraestructura"
  type        = string
  default     = "eu-west-1"
}

variable "tipo_instancia" {
  description = "Tamaño de la máquina virtual EC2"
  type        = string
  default     = "t3.micro"
}

variable "nombre_servidor" {
  description = "Etiqueta Name para identificar nuestro servidor web"
  type        = string
  default     = "servidor-variables-miguel"
}

variable "ami_id" {
  description = "AMI Amazon Linux 2023 en eu-west-1"
  type        = string
  default     = "ami-062a8901a5ddcf280"
}
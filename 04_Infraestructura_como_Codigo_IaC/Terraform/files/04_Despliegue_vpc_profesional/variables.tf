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

variable "cidr_vpc" {
  description = "Bloque CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cidr_subred_publica" {
  description = "Bloque CIDR para la subred pública"
  type        = string
  default     = "10.0.1.0/24"
}

variable "entorno" {
  description = "Etiqueta del entorno"
  type        = string
  default     = "Produccion"
}
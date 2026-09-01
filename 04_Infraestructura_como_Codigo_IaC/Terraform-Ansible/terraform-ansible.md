# Integración Terraform + Ansible en AWS

## 🗺️ Nuestro Roadmap Práctico
+ Este es el mapa de carretera que seguiremos paso a paso:
```
┌─────────────────────────────────────────────────────────┐
│ LECCIÓN 1 (HOY): Preparar tu entorno de trabajo         │
│ ➔ Instalar AWS CLI, Terraform y Ansible                │
│ ➔ Conectar la terminal con tus créditos de AWS         │
└──────────────────────────┬──────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│ LECCIÓN 2: Terraform crea la infraestructura            │
│ ➔ Escribir el código para crear una EC2                │
│ ➔ Generar una clave SSH y las reglas de Firewall       │
└──────────────────────────┬──────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│ LECCIÓN 3: El puente (Generar el inventario)            │
│ ➔ Hacer que Terraform cree el archivo 'hosts.ini'      │
└──────────────────────────┬──────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│ LECCIÓN 4: Ansible toma el control                      │
│ ➔ Conectarnos a AWS vía SSH usando Ansible             │
│ ➔ Instalar Nginx y desplegar nuestra web               │
└─────────────────────────────────────────────────────────┘
```

## 🏁 LECCIÓN 1: Preparación del Entorno de Trabajo
+ Hoy vamos a dejar la terminal lista para comunicarse con tu cuenta de AWS.

1. Paso 1: Comprobar las herramientas instaladas
```Bash
aws --version
terraform --version
ansible --version
```

2. Paso 2: Crear tus claves SSH en local
+ Ansible necesita una clave SSH pública/privada para entrar a la máquina de AWS sin pedirte contraseña. Vamos a generar esa clave en tu propio ordenador:

+ Ejecuta este comando en tu terminal:
```Bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/aws_ansible_key -N ""
Comprueba que se han creado dos archivos con este comando:
```
```Bash
ls -l ~/.ssh/aws_ansible_key*
```
+ Deberías ver dos archivos:
    - aws_ansible_key: Es tu clave privada (guárdala en secreto).
    - aws_ansible_key.pub: Es tu clave pública (se la daremos a AWS mediante Terraform).

3. Paso 3: Conectar tu terminal con tus créditos de AWS Learner Lab / AWS Academy:
+ Entra en tu panel de AWS Academy / Learner Lab.
+ Haz clic en el botón que dice "AWS CLI" (suele estar arriba a la derecha, cerca del estado de la consola).
+ Verás un bloque de texto con credenciales temporales que se parecen a esto:
```Bash
export AWS_ACCESS_KEY_ID="ASIA..."
export AWS_SECRET_ACCESS_KEY="..."
AWS_SESSION_TOKEN="..."
```
+ Comprueba que estás conectado ejecutando:
```Bash
aws sts get-caller-identity
```

## 🏁 LECCIÓN 2: Definir la Infraestructura en AWS con Terraform
+ Hoy crearemos una máquina EC2 en AWS. Pero en lugar de hacerlo a través del panel gráfico de AWS, la escribiremos en código.
+ Para que una máquina EC2 funcione de forma segura y accesible por SSH, Terraform necesita crear 3 elementos esenciales:
    1. Un Security Group (Firewall): Abre el puerto 22 (SSH para Ansible) y el puerto 80 (HTTP para ver la web que instalaremos después).
    2. Un Key Pair (Clave SSH en AWS): Le entrega a AWS tu clave pública (aws_ansible_key.pub) para que la inyecte en la máquina virtual.
    3. La Instancia EC2 (Servidor): La máquina virtual en sí (usaremos Ubuntu Server en us-east-1 o tu región predeterminada).

+ Paso 1: Crear el archivo main.tf
```bash
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
  instance_type = "t2.micro" # Incluida en la capa gratuita / lab

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
```

## 🏁 LECCIÓN 3: El Puente — Generar el Inventario hosts.ini con Terraform
+ Ahora mismo tenemos un servidor en la nube con la IP 54.91.170.155. Para no tener que escribir esa IP a mano en Ansible ni tener que actualizarla cada vez que recreemos la infraestructura, haremos que Terraform escriba el archivo de inventario hosts.ini automáticamente.

+ Paso 1: Añadir el recurso local_file a tu main.tf
    - Abre tu archivo main.tf y añade el siguiente bloque de código al final de todo el archivo:

```bash
# 7. Generar el archivo de inventario para Ansible
resource "local_file" "inventario_ansible" {
  filename = "${path.module}/hosts.ini"

  content = <<EOF
[webservers]
${aws_instance.servidor_web.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/aws_ansible_key
EOF
}
```
> filename: Crea un archivo llamado hosts.ini en tu carpeta actual.  
> content: Crea el grupo [webservers] e inserta la IP pública que AWS le dio a la máquina, diciéndole a Ansible que el usuario es ubuntu y la clave para entrar es ~/.ssh/aws_ansible_key.

+ Comprobar que funciona:
    - terraform init (para las dependencias del local file)
    - terraform plan
    - terraform apply
    - cat hosts.ini (comprobar que sale el grupo webservers, ip, ansible user, etc)
    - ver si funciona el ping con comando ansible a aws: `ansible webservers -i hosts.ini -m ping --ssh-common-args='-o StrictHostKeyChecking=no'`
    ```bash
    54.91.170.155 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.10"
    },
    "changed": false,
    "ping": "pong"
    }
    ```
    > Terraform levantó la máquina virtual en la nube de AWS.  
    > Terraform escribió automáticamente la IP y los parámetros SSH en hosts.ini.  
    > Ansible leyó ese hosts.ini, viajó por SSH hasta AWS usando tu clave privada y se comunicó con el interprete de Python del servidor Ubuntu.  

## 🏁 LECCIÓN 4: Ansible toma el control (Despliegue de la Aplicación)
+ Ahora que tenemos la infraestructura lista y conectada, entramos en la fase de configuración: le daremos instrucciones a Ansible para que convierta esa máquina vacía en un servidor web real.

+ Paso 1: Crear el Playbook de Ansible (playbook.yml)
    - En la misma carpeta (04_Infraestructura_como_Codigo_IaC), crea un nuevo archivo llamado playbook.yml.

```YAML
---
- name: Configurar Servidor Web Nginx
  hosts: webservers
  become: true # Se ejecuta como usuario root (sudo)

  tasks:
    - name: Actualizar el índice de paquetes de Ubuntu (apt update)
      apt:
        update_cache: yes

    - name: Instalar el servidor web Nginx
      apt:
        name: nginx
        state: present

    - name: Crear una página web personalizada de bienvenida
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>DevOps Lab - Terraform + Ansible</title>
              <style>
                  body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background-color: #f4f4f9; }
                  h1 { color: #2c3e50; }
                  p { color: #34495e; font-size: 1.2em; }
                  .card { background: white; padding: 20px; display: inline-block; border-radius: 8px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }
              </style>
          </head>
          <body>
              <div class="card">
                  <h1>🚀 Despliegue Exitoso!</h1>
                  <p>Infraestructura creada con <strong>Terraform</strong></p>
                  <p>Configuracion y servidor Nginx gestionado por <strong>Ansible</strong></p>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        mode: '0644'

    - name: Asegurar que Nginx esta iniciado y habilitado en el arranque
      service:
        name: nginx
        state: started
        enabled: yes
```
> become: true: Da permisos de administrador (sudo) para instalar software en el sistema.  
> apt: Módulo de Ansible para gestionar paquetes en sistemas Debian/Ubuntu.  
> copy: Reemplaza la página por defecto de Nginx por un sitio HTML que hemos diseñado.  
> service: Garantiza que el servicio Nginx esté activo y se reinicie automáticamente si la máquina se apaga.  

+ Paso 2: Ejecutar el Playbook contra AWS
```Bash
ansible-playbook -i hosts.ini playbook.yml --ssh-common-args='-o StrictHostKeyChecking=no'
```
> Es un parámetro de seguridad de SSH que le dice a Ansible: "No me preguntes si confío en esta máquina la primera vez que me conecto" (fichero knowhosts y el figerprint).

+ Verás cómo Ansible ejecuta tarea por tarea mostrando los estados ok y changed.
```bash
miguel@DESKTOP-G47I0DM:~/projects/devops/mamoros-dev.github.io/casos-reales/04_Infraestructura_como_Codigo_IaC$ ansible-playbook -i hosts.ini playbook.yml --ssh-common-args='-o StrictHostKeyChecking=no'

PLAY [Configurar Servidor Web Nginx] ******************************************************************************************************************************************************

TASK [Gathering Facts] ********************************************************************************************************************************************************************
[WARNING]: Host '54.91.170.155' is using the discovered Python interpreter at '/usr/bin/python3.10', but future installation of another Python interpreter could cause a different interpreter to be discovered. See https://docs.ansible.com/ansible-core/2.20/reference_appendices/interpreter_discovery.html for more information.
ok: [54.91.170.155]

TASK [Actualizar el índice de paquetes de Ubuntu (apt update)] ****************************************************************************************************************************
changed: [54.91.170.155]

TASK [Instalar el servidor web Nginx] *****************************************************************************************************************************************************
changed: [54.91.170.155]

TASK [Crear una página web personalizada de bienvenida] ***********************************************************************************************************************************
changed: [54.91.170.155]

TASK [Asegurar que Nginx esta iniciado y habilitado en el arranque] ***********************************************************************************************************************
ok: [54.91.170.155]

PLAY RECAP ********************************************************************************************************************************************************************************
54.91.170.155              : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

+ Paso 3: Comprobación final en tu navegador
    - Abre cualquier navegador web (Chrome, Edge, Firefox) y entra en la dirección IP pública de tu servidor: http://54.91.170.155
    ```bash
    Despliegue Exitoso!
    Infraestructura creada con Terraform

    Configuracion y servidor Nginx gestionado por Ansible
    ```

## 🚀 Lección 5 : Inventarios Dinámicos con Ansible + AWS
1. 📌 Paso 1: Crear el main.tf adaptado para Inventarios Dinámicos
+ En esta ocasión no usaremos local_file. En su lugar, añadiremos etiquetas (Tags) estratégicas a la máquina virtual para que Ansible sepa qué rol cumple en nuestra infraestructura.

+ Crea un archivo llamado main.tf dentro de Terraform-Ansible/02_inventario_dinamico/ con el siguiente código:
```Terraform
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "personal"
}

# 1. Clave SSH pública
resource "aws_key_pair" "mi_clave_ssh" {
  key_name   = "clave-ansible-dynamic"
  public_key = file("~/.ssh/aws_ansible_key.pub")
}

# 2. Grupo de Seguridad (Firewall)
resource "aws_security_group" "sg_web" {
  name        = "sg_ansible_dynamic"
  description = "Permitir SSH y HTTP"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. AMI de Ubuntu Jammy 22.04
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 4. Instancia EC2 con TAGS ESTRATÉGICOS
resource "aws_instance" "servidor_web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"

  key_name               = aws_key_pair.mi_clave_ssh.key_name
  vpc_security_group_ids = [aws_security_group.sg_web.id]

  # ESTAS ETIQUETAS LAS LEERÁ ANSIBLE DE FORMA DINÁMICA:
  tags = {
    Name        = "EC2-Ansible-Dynamic"
    Environment = "Dev"
    Role        = "webservers" # <-- Tag principal de filtrado
  }
}

output "ip_publica_servidor" {
  value       = aws_instance.servidor_web.public_ip
  description = "IP Pública asignada a la instancia EC2"
}
```
> Con TAGS, Le estamos pegando una "pegatina" virtual a la máquina dentro de la base de datos de AWS. AWS guarda esa máquina con la etiqueta Role: webservers. Ahora la máquina no es solo una IP anónima; tiene una identidad.
2. 📌 Paso 2: Desplegar la infraestructura con Terraform
+ Ejecuta los siguientes comandos en tu terminal dentro de 02_inventario_dinamico:
```Bash
terraform init
terraform apply -auto-approve
```
3. 📌 Paso 3: Instalar la librería boto3 para Ansible
+ Para que Ansible pueda consultar la API de AWS en tiempo real, necesita la librería Python oficial de AWS llamada boto3.

+ Ejecuta en tu WSL:
```Bash
sudo apt install -y python3-boto3 python3-botocore
(Si pip te diera un error de paquete no encontrado, instala primero pip con sudo apt install python3-pip -y).
```

4. 📌 Paso 4: Configurar el archivo de inventario dinámico (aws_ec2.yml)
+ Crea un archivo llamado `aws_ec2.yml` en la misma carpeta.
+ ⚠️ Importante: Por convención de Ansible, el archivo debe terminar en _ec2.yml o _ec2.yaml para que active automáticamente el plugin de AWS.
```YAML
plugin: aws_ec2
regions:
  - us-east-1 # Ajusta a tu región si utilizas otra diferente

# Crea automáticamente grupos en Ansible basados en el valor del Tag "Role"
keyed_groups:
  - key: tags.Role
    prefix: tag

# Configuración de red y usuario para la conexión SSH automática
hostnames:
  - ip-address

compose:
  ansible_host: public_ip_address
  ansible_user: "'ubuntu'"
  ansible_ssh_private_key_file: "'~/.ssh/aws_ansible_key'"
```
> 1- Lee la primera línea de aws_ec2.yml: plugin: aws_ec2.  
> 2- Al ver ese plugin, Ansible busca en tu sistema la librería boto3.  
> 3- Usa tus credenciales de AWS (las que configuraste con el CLI) para hacer una llamada a la API de AWS en la región us-east-1.  
> 4- Le dice a AWS: "Dame la lista completa de todas las instancias EC2 activas".  
> 5- Cuando AWS le responde con los datos de las máquinas, aws_ec2.yml los procesa con este bloque:  `keyed_groups`. Esto le ordena a Ansible: "Crea grupos automáticos agrupando las máquinas según la etiqueta Role que tengan puesta en AWS y ponle el prefijo tag_".

5. 📌 Paso 5: Probar el descubrimiento dinámico con Ansible
+ Una vez creado aws_ec2.yml, ejecuta este comando en la terminal para que Ansible consulte a AWS:

```Bash
ansible-inventory -i aws_ec2.yml --graph
```

6. 🎯 Tu turno (Paso a la acción):
- Posiciónate en 02_inventario_dinamico.
- Crea main.tf, ejecuta terraform init y terraform apply.
```bash
Plan: 1 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + ip_publica_servidor = (known after apply)
aws_instance.servidor_web: Creating...
aws_instance.servidor_web: Still creating... [00m10s elapsed]
aws_instance.servidor_web: Creation complete after 14s [id=i-06d13503d21633e56]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.

Outputs:

ip_publica_servidor = "44.197.244.111"
```
- Instala boto3 y crea aws_ec2.yml.
- Lanza el comando ansible-inventory -i aws_ec2.yml --graph.
```bash
miguel@DESKTOP-G47I0DM:~/projects/devops/mamoros-dev.github.io/casos-reales/04_Infraestructura_como_Codigo_IaC/Terraform-Ansible/02_inventario_dinamico$ ansible-inventory -i aws_ec2.yml --graph

@all:
  |--@ungrouped:
  |--@aws_ec2:
  |  |--44.197.244.111
  |--@tag_webservers:
  |  |--44.197.244.111
```
> No significa que tengas dos máquinas ni que esté duplicado. Significa que la misma máquina pertenece a dos clasificaciones/grupos diferentes a la vez:  
> @aws_ec2: Es el grupo por defecto donde el plugin mete TODAS las máquinas que encuentra en tu cuenta de AWS, independientemente de lo que sean.  
> @tag_webservers: Es el grupo específico que creó Ansible al leer el tag Role = webservers.  

+ 💡 Ejemplo de la vida real:
```bash
# Piensa en una empresa con 50 servidores en AWS:

10 servidores tienen el tag Role = webservers

20 servidores tienen el tag Role = databases

20 servidores tienen el tag Role = app

# Cuando Ansible consulte a AWS:

En el grupo general @aws_ec2 verás los 50 servidores.

En el grupo @tag_webservers verás solo los 10 servidores web.

En el grupo @tag_databases verás solo los 20 de base de datos.
```
> Por eso cuando ejecutamos nuestro Playbook, en lugar de darle una IP a fuego, le diremos a Ansible: "Aplica estos cambios al grupo tag_webservers".

> Si mañana Terraform crea 5 servidores web más con esa misma etiqueta, no tendrás que cambiar ni una sola línea de código en Ansible. Ansible descubrirá los 5 nuevos servidores solo y les instalará Nginx a todos a la vez.

+ Probar la conectividad SSH con el Inventario Dinámico:
  - Para verificar que Ansible puede conectarse a la máquina descubierta por AWS, ejecuta este comando en tu terminal dentro de 02_inventario_dinamico:
```Bash
ansible tag_webservers -i aws_ec2.yml -m ping --ssh-common-args='-o StrictHostKeyChecking=no'
```

+ Resultado ok:
```ansible
44.197.244.111 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python3.10"
    },
    "changed": false,
    "ping": "pong"
}
```

+ Crear el archivo playbook.yml
  - Crea el archivo playbook.yml dentro de la carpeta 02_inventario_dinamico/:

```YAML
---
- name: Configurar Servidor Web vía Inventario Dinámico
  hosts: tag_webservers # <-- Apunta al grupo dinámico creado a partir del Tag Role=webservers
  become: true

  tasks:
    - name: Actualizar índice de paquetes de Ubuntu
      apt:
        update_cache: yes

    - name: Instalar Nginx
      apt:
        name: nginx
        state: present

    - name: Crear página web de prueba (Inventario Dinámico)
      copy:
        content: |
          <!DOCTYPE html>
          <html>
          <head>
              <title>DevOps Lab - Inventario Dinámico</title>
              <style>
                  body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background-color: #eef2f5; }
                  h1 { color: #27ae60; }
                  p { color: #2c3e50; font-size: 1.2em; }
                  .card { background: white; padding: 25px; display: inline-block; border-radius: 10px; box-shadow: 0 4px 10px rgba(0,0,0,0.15); }
              </style>
          </head>
          <body>
              <div class="card">
                  <h1>⚡ Inventario Dinámico Operativo</h1>
                  <p>Instancia descubierta automáticamente vía API de AWS mediante el Tag <strong>Role=webservers</strong>.</p>
              </div>
          </body>
          </html>
        dest: /var/www/html/index.html
        mode: '0644'

    - name: Iniciar y habilitar servicio Nginx
      service:
        name: nginx
        state: started
        enabled: yes
```
+ Ejecutar el Playbook:
  - Ejecuta el Playbook indicándole a Ansible que use el inventario dinámico aws_ec2.yml:
```Bash
ansible-playbook -i aws_ec2.yml playbook.yml --ssh-common-args='-o StrictHostKeyChecking=no'
```

+ Comprobación y limpieza:
```bash
TASK [Gathering Facts] ****************************************************************************************************************************************************************************************************
[WARNING]: Host '44.197.244.111' is using the discovered Python interpreter at '/usr/bin/python3.10', but future installation of another Python interpreter could cause a different interpreter to be discovered. See https://docs.ansible.com/ansible-core/2.20/reference_appendices/interpreter_discovery.html for more information.
ok: [44.197.244.111]

TASK [Actualizar índice de paquetes de Ubuntu] ****************************************************************************************************************************************************************************
changed: [44.197.244.111]

TASK [Instalar Nginx] *****************************************************************************************************************************************************************************************************
changed: [44.197.244.111]

TASK [Crear página web de prueba (Inventario Dinámico)] *******************************************************************************************************************************************************************
changed: [44.197.244.111]

TASK [Iniciar y habilitar servicio Nginx] *********************************************************************************************************************************************************************************
ok: [44.197.244.111]

PLAY RECAP ****************************************************************************************************************************************************************************************************************
44.197.244.111             : ok=5    changed=3    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```

+ Web con la ip 44.197.244.111:
`Inventario DinÃ¡mico Operativo: Instancia descubierta automáticamente vi­a API de AWS mediante el Tag Role=webservers.`  

+ Borramos todo `terraform destroy -auto-approve`


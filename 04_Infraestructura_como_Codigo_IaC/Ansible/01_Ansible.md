# ANSIBLE

+ 🤖 ¿Qué es Ansible y por qué es tu siguiente paso?
Imagínate este caso real: entras a trabajar en una empresa y te piden configurar 15 servidores Ubuntu en la nube de AWS. En todos ellos tienes que:
    - Actualizar el sistema.
    - Instalar el motor de Docker.
    - Crear los usuarios y darles permisos.
    - Asegurar los puertos.

+ Hacerlo a mano entrando uno a uno por SSH te llevaría todo el día, te equivocarías en alguna línea y querrías tirarte por la ventana.

+ Para solucionar esto nació Ansible. Es una herramienta que te permite escribir una "receta de cocina" en un archivo de texto YAML (llamado Playbook). En ese archivo pones con palabras sencillas lo que quieres: "Instala docker", "Crea el usuario Miguel", "Copia este archivo". Luego, le das al play, y Ansible se conecta en paralelo a los 15 servidores y los configura en 20 segundos sin que tú toques nada.

+ Es "Agentless" (Sin Agentes): Otras herramientas de automatización te obligan a instalar un programa "guardián" (un agente) en cada servidor que quieres controlar. Ansible no. Ansible es limpio: se instala solo en tu máquina de control (tu Ubuntu) y se conecta a los demás servidores usando SSH (el mismo sistema que usa Vagrant para entrar a la máquina). Si puedes hacer SSH a un servidor, puedes controlarlo con Ansible.

+ Ansible es idempotente. Tú no le das órdenes de acción, le defines el Estado Deseado. Le dices: "Quiero que exista la carpeta X".
    - Si la carpeta no existe, Ansible la crea.
    - Si la carpeta ya existe, Ansible la mira, ve que todo está correcto, no hace nada y sigue adelante sin romper. Puedes lanzar el mismo código 1000 veces que el resultado siempre será perfecto y seguro.


## INSTALACIÓN

+ Seguimos estos comandos para la instalación de ansible:
```
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

ansible --version
```

## FUNCIONAMIENTO DE ANSIBLE

+ [DOCUMENTACION ANSIBLE](docs.ansible.com)  
+ [DOCUMENTACION MODULOS](https://docs.ansible.com/projects/ansible/latest/collections/ansible/builtin/index.html)

+ 3 Conceptos:
    - El Nodo de Control (Control Node): Es tu máquina virtual Ubuntu. Es el cerebro donde acabamos de instalar Ansible y desde donde ejecutaremos los comandos.

    - El Inventario (Inventory / Hosts): Un archivo de texto simple donde le decimos a Ansible a qué máquinas queremos conectarnos (direcciones IP, nombres de servidor, claves SSH). Mañana configuraremos este archivo para decirle a Ansible que se conecte a "ella misma" (localhost) para hacer las pruebas.

    - El Playbook (La Receta): El archivo .yml donde escribimos en lenguaje humano lo que queremos que pase en los servidores.

+ PLAYBOOK:
```
+ Ansible no inventa nada; todo se basa en una jerarquía fija. Un Playbook es como una obra de teatro (de ahí su nombre, Libro de Jugadas).
    - El Elenco (hosts): A qué servidores afecta.
    - Los Permisos (become): Con qué rango de usuario actúa.
    - El Guion (tasks): Las acciones que se van a ejecutar en orden.

+ Si entras a la Documentación Oficial de Ansible (docs.ansible.com), verás que para interactuar con el sistema operativo no usamos comandos de terminal, usamos Módulos.

+ El secreto de ansible.builtin.xxxx: Ansible viene de fábrica con miles de "piezas de LEGO" llamadas módulos integrados (builtin). Cada una sirve para una sola cosa en el sistema operativo:
    - ¿Quieres gestionar grupos de Linux? Usas el módulo ansible.builtin.group.
    - ¿Quieres gestionar usuarios? Usas el módulo ansible.builtin.user.
    - ¿Quieres instalar cosas con el gestor de paquetes de Ubuntu (APT)? Usas el módulo ansible.builtin.apt.
```

+ Los módulos más usados:
```
ansible.builtin.apt: Para instalar, actualizar o borrar programas en Ubuntu/Debian (como harías con apt install).

ansible.builtin.copy: Para copiar un archivo de configuración que tengas en tu VS Code hacia el servidor de producción.

ansible.builtin.file: Para crear carpetas, borrar archivos o cambiar los permisos y propietarios de un directorio (chmod/chown).

ansible.builtin.user: Para gestionar usuarios del sistema (crearlos, meterlos en grupos, asignarles contraseñas).

ansible.builtin.service (o systemd): Para arrancar, parar o reiniciar servicios del sistema operativo (por ejemplo, asegurarte de que el motor de Docker esté encendido).

ansible.builtin.shell: El botón de emergencia. Si necesitas ejecutar un comando de Linux muy raro o a medida que no tiene módulo oficial, usas este para escupir el comando directamente en la terminal.
```

## PRIMER TEST: Instalar paquetes y creación de usuario en local

+ Para que Ansible funcione, necesita dos archivos en su carpeta de proyecto:
    - El Inventario (hosts): La lista de equipos (IPs) a las que tiene que llamar.
    - El Playbook (playbook.yml): La lista de tareas que tiene que ejecutar en esas máquinas.
    > Como hoy estamos aprendiendo la herramienta, vamos a configurar Ansible para que el Nodo de Control (tu Ubuntu) se controle a sí mismo (lo que en ingeniería llamamos localhost o local).

+ Vamos a crear el archivo inventario HOSTS donde le decimos a Ansible dónde trabajar:
```
vi hosts

[mis_servidores]
localhost ansible_connection=local
```
> Creamos un grupo de servidores llamado [mis_servidores]. Dentro, añadimos a localhost (esta misma máquina) y le añadimos el parámetro ansible_connection=local para avisarle de que no necesita usar claves SSH externas, sino que ejecute los comandos directamente en su propia consola.

+ Ahora vamos a crear el playbook(el archivo YAML). Vamos a pedirle a Ansible tres tareas reales que simulan la preparación de un servidor de producción:
1. Crear un grupo de usuarios de seguridad llamado devops.
2. Crear un usuario de sistema llamado miguel_admin dentro de ese grupo.
3. Asegurarse de que el servidor tenga instalado el editor curl (esencial para bajarse cosas de internet).
```
vi primer_playbook.yml

---
- name: Preparar servidor de desarrollo local
  hosts: mis_servidores
  become: true  # Le dice a Ansible que use permisos de administrador (sudo)

  tasks:
    - name: 1. Asegurar que existe el grupo devops
      ansible.builtin.group:
        name: devops
        state: present

    - name: 2. Crear el usuario miguel_admin en el grupo devops
      ansible.builtin.user:
        name: miguel_admin
        group: devops
        shell: /bin/bash
        state: present

    - name: 3. Asegurar que curl está instalado en el sistema
      ansible.builtin.apt:
        name: curl
        state: present
```
> become: true: Como crear usuarios e instalar programas requiere permisos de root, esto le dice a Ansible: "Usa el sudo automáticamente cuando lo necesites".  
> ansible.builtin.xxx: Son los módulos de Ansible. En lugar de escribir comandos de Bash como useradd o apt install, usamos los módulos oficiales de Ansible. Esto es lo que garantiza la idempotencia.  
> state: present: Esto es el Estado Deseado. No le estás diciendo "instala" o "crea". Le estás diciendo: "Quiero que al terminar, esto esté presente en el sistema".  

+ Para lanzar esta automatización, usamos el comando ansible-playbook, pasándole el archivo de inventario con el flag -i y luego el archivo de la receta. Ejecuta:
`ansible-playbook -i hosts primer_playbook.yml` 
```
PLAY [Preparar servidor de desarrollo local] ***********************************

TASK [Gathering Facts] *********************************************************
ok: [localhost]

TASK [1. Asegurar que existe el grupo devops] **********************************
changed: [localhost]

TASK [2. Crear el usuario miguel_admin en el grupo devops] *********************
changed: [localhost]

TASK [3. Asegurar que curl está instalado en el sistema] ***********************
ok: [localhost]

PLAY RECAP *********************************************************************
localhost                  : ok=4    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0  
```
> Gathering Facts (Recogiendo hechos): Es la primera tarea que hace Ansible siempre por defecto automáticamente. Se conecta al servidor y "cotillea" su sistema: mira cuánta RAM tiene, qué versión de Ubuntu usa, qué IP tiene, etc. Como ha podido leerlo sin problemas, te pone ok.  
> changed (Cambiado): ¡Ojo a esta palabra! En el lenguaje de Ansible, changed significa: "Oye, Miguel, he mirado el servidor, he visto que el grupo 'devops' no existía, así que me he puesto manos a la obra y lo he creado". El sistema ha sido modificado.  
> ok: Fíjate que en la tarea de instalar curl no te ha puesto changed, te ha puesto ok. ¿Por qué? Porque tu máquina virtual de Vagrant ya venía con curl instalado de fábrica. Ansible, aplicando la idempotencia, comprobó si estaba instalado, vio que sí, y pasó de largo sin reinstalar nada ni perder tiempo.  


## SEGUNDO TEST: Instalar Docker a máquinas remotas

+ Imagínate que te dan un servidor completamente limpio en AWS y te dicen: "Miguel, prepáralo para producción e instálale Docker".  

+ Modificamos el fichero hosts:
```
[servidores_web]
127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/id_rsa
```
> Le estamos diciendo a Ansible: "Tienes un servidor en la dirección local, pero quiero que salgas por el puerto 2222 (el puerto SSH que usa Vagrant) y te loguees con el usuario vagrant usando su clave de seguridad". Así Ansible simula una conexión de red real.  

+ Creamos un playbook para instalar los paquetes docker y activar el servicio para que siempre esté Running:
```
---
- name: Playbook para instalar y configurar Docker en producción
  hosts: servidores_web
  become: true

  tasks:
    - name: 1. Instalar dependencias necesarias para Docker
      ansible.builtin.apt:
        name:
          - apt-transport-https
          - ca-certificates
          - gnupg
          - lsb-release
        state: present
        update_cache: yes

    - name: 2. Añadir la clave oficial de repositorio de Docker
      ansible.builtin.apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: 3. Añadir el repositorio de Docker a las fuentes de Ubuntu
      ansible.builtin.apt_repository:
        repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable
        state: present

    - name: 4. Instalar el motor de Docker (Docker CE)
      ansible.builtin.apt:
        name: docker-ce
        state: present
        update_cache: yes

    - name: 5. Asegurar que el servicio de Docker esté encendido y activo
      ansible.builtin.service:
        name: docker
        state: started
        enabled: yes
```
> update_cache: yes: Equivale a hacer un apt update justo antes de instalar. Asegura que bajamos la última versión.  
> ansible.builtin.apt_key y apt_repository: En las empresas no se descarga software de cualquier sitio. Estos módulos aseguran que Ubuntu confíe en el servidor oficial de Docker de forma segura.  
> enabled: yes (En la tarea 5): Esto es clave. Le dice al sistema operativo: "Si el servidor se apaga o se cae por un fallo eléctrico, en cuanto vuelva a arrancar, enciende Docker automáticamente".  

+ Creamos llaves SSH para hablar directamente conmigo mismo por SSH:  
```
ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

+ Lanzamos el playbook: `ansible-playbook -i hosts docker_playbook.yml`

+ Nos da error:
```
vagrant@ubuntu-focal:~/infraestructura/ansible$ ansible-playbook -i hosts docker_playbook.yml

PLAY [Playbook para instalar y configurar Docker en producción] ****************

TASK [Gathering Facts] *********************************************************
fatal: [127.0.0.1]: UNREACHABLE! => {"changed": false, "msg": "Failed to connect to the host via ssh: ssh: connect to host 127.0.0.1 port 2222: Connection refused", "unreachable": true}

PLAY RECAP *********************************************************************
127.0.0.1                  : ok=0    changed=0    unreachable=1    failed=0    skipped=0    rescued=0    ignored=0
```
> Eso pasa porque la conexión ssh de dentro del vagrant va por el puerto standard 22 y no el 2222. Modificamos el host a 22 y debería funcionar

+ Lanzamos con la modificación y nos sale otro error: 
```
[servidores_web]
127.0.0.1 ansible_port=2222 ansible_user=vagrant ansible_ssh_private_key_file=/home/vagrant/.ssh/id_rsa
```  

```
vagrant@ubuntu-focal:~/infraestructura/ansible$ ansible-playbook -i hosts docker_playbook.yml

PLAY [Playbook para instalar y configurar Docker en producción] ****************

TASK [Gathering Facts] *********************************************************
The authenticity of host '127.0.0.1 (127.0.0.1)' can't be established.
ECDSA key fingerprint is SHA256:I9gPRtkfe7DQL2r/TreCsmz90KHTVT7LDXi3ZEXVnQk.
Are you sure you want to continue connecting (yes/no/[fingerprint])? ues
Please type 'yes', 'no' or the fingerprint: yes
ok: [127.0.0.1]

TASK [1. Instalar dependencias necesarias para Docker] *************************
changed: [127.0.0.1]

TASK [2. Añadir la clave oficial de repositorio de Docker] *********************
changed: [127.0.0.1]

TASK [3. Añadir el repositorio de Docker a las fuentes de Ubuntu] **************
An exception occurred during task execution. To see the full traceback, use -vvv. The error was: apt_pkg.Error: E:Conflicting values set for option Signed-By regarding source https://download.docker.com/linux/ubuntu/ focal: /etc/apt/keyrings/docker.gpg != , E:The list of sources could not be read.
fatal: [127.0.0.1]: FAILED! => {"changed": false, "module_stderr": "Shared connection to 127.0.0.1 closed.\r\n", "module_stdout": "Traceback (most recent call last):\r\n  File \"/home/vagrant/.ansible/tmp/ansible-tmp-1780267222.1894581-4512-76801550665067/AnsiballZ_apt_repository.py\", line 107, in <module>\r\n    _ansiballz_main()\r\n  File \"/home/vagrant/.ansible/tmp/ansible-tmp-1780267222.1894581-4512-76801550665067/AnsiballZ_apt_repository.py\", line 99, in _ansiballz_main\r\n    invoke_module(zipped_mod, temp_path, ANSIBALLZ_PARAMS)\r\n  File \"/home/vagrant/.ansible/tmp/ansible-tmp-1780267222.1894581-4512-76801550665067/AnsiballZ_apt_repository.py\", line 47, in invoke_module\r\n    runpy.run_module(mod_name='ansible.modules.apt_repository', init_globals=dict(_module_fqn='ansible.modules.apt_repository', _modlib_path=modlib_path),\r\n  File \"/usr/lib/python3.8/runpy.py\", line 207, in run_module\r\n    return _run_module_code(code, init_globals, run_name, mod_spec)\r\n  File \"/usr/lib/python3.8/runpy.py\", line 97, in _run_module_code\r\n    _run_code(code, mod_globals, init_globals,\r\n  File \"/usr/lib/python3.8/runpy.py\", line 87, in _run_code\r\n    exec(code, run_globals)\r\n  File \"/tmp/ansible_ansible.builtin.apt_repository_payload_35ew1dxs/ansible_ansible.builtin.apt_repository_payload.zip/ansible/modules/apt_repository.py\", line 668, in <module>\r\n  File \"/tmp/ansible_ansible.builtin.apt_repository_payload_35ew1dxs/ansible_ansible.builtin.apt_repository_payload.zip/ansible/modules/apt_repository.py\", line 645, in main\r\n  File \"/usr/lib/python3/dist-packages/apt/cache.py\", line 170, in __init__\r\n    self.open(progress)\r\n  File \"/usr/lib/python3/dist-packages/apt/cache.py\", line 232, in open\r\n    self._cache = apt_pkg.Cache(progress)\r\napt_pkg.Error: E:Conflicting values set for option Signed-By regarding source https://download.docker.com/linux/ubuntu/ focal: /etc/apt/keyrings/docker.gpg != , E:The list of sources could not be read.\r\n", "msg": "MODULE FAILURE\nSee stdout/stderr for the exact error", "rc": 1}

PLAY RECAP *********************************************************************
127.0.0.1                  : ok=3    changed=2    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0
```
> Hay un problema con la ubicación de la firma de la tarea 3. Cuando instalamos docker le indicamos la ruta en concreto donde se guardaba. Es lo que tenemoe que poner en la tarea 3

```
---
- name: Playbook para instalar y configurar Docker en producción
  hosts: servidores_web
  become: true

  tasks:
    - name: 1. Instalar dependencias necesarias para Docker
      ansible.builtin.apt:
        name:
          - apt-transport-https
          - ca-certificates
          - gnupg
          - lsb-release
        state: present
        update_cache: yes

    - name: 2. Añadir la clave oficial de repositorio de Docker
      ansible.builtin.apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: 3. Añadir el repositorio de Docker a las fuentes de Ubuntu
      ansible.builtin.apt_repository:
        repo: deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu focal stable
        state: present

    - name: 4. Instalar el motor de Docker (Docker CE)
      ansible.builtin.apt:
        name: docker-ce
        state: present
        update_cache: yes

    - name: 5. Asegurar que el servicio de Docker esté encendido y activo
      ansible.builtin.service:
        name: docker
        state: started
        enabled: yes
```

+ Lanzamos de nuevo, antes hacemos una limpieza de repos y cachés:
```
sudo rm -f /etc/apt/sources.list.d/download_docker_com_linux_ubuntu.list
sudo apt-get clean && sudo apt-get update
```
> Borra de forma fulminante (rm -f) un archivo de configuración específico dentro de la carpeta sources.list.d. En Ubuntu, la carpeta /etc/apt/sources.list.d/ es la libreta de direcciones donde el sistema operativo apunta los servidores externos de donde puede descargarse programas (los famosos repositorios).  

> ¿Qué hace sudo apt-get clean? Borra todos los archivos instaladores (.deb) que Ubuntu se ha ido descargando en el pasado y que se quedan guardados en el disco duro ocupando espacio (la basura temporal del sistema).  
> ¿Qué hace sudo apt-get update? Le dice a Ubuntu: "Conéctate a internet ahora mismo, habla con todos los servidores de software que tengas en tu lista y descárgate la lista actualizada de los programas que existen".  

> ¿Por qué lo hicimos y en qué afecta? Ubuntu es un sistema eficiente: no busca en internet cada vez que tú pides instalar algo; busca en una base de datos local (un caché) que tiene guardada en el disco para ir más rápido.

+ Resultado:  
```
vagrant@ubuntu-focal:~/infraestructura/ansible$ ansible-playbook -i hosts docker_playbook.yml

PLAY [Playbook para instalar y configurar Docker en producción] ****************

TASK [Gathering Facts] *********************************************************
ok: [127.0.0.1]

TASK [1. Instalar dependencias necesarias para Docker] *************************
ok: [127.0.0.1]

TASK [2. Añadir la clave oficial de repositorio de Docker] *********************
ok: [127.0.0.1]

TASK [3. Añadir el repositorio de Docker a las fuentes de Ubuntu] **************
ok: [127.0.0.1]

TASK [4. Instalar el motor de Docker (Docker CE)] ******************************
ok: [127.0.0.1]

TASK [5. Asegurar que el servicio de Docker esté encendido y activo] ***********
ok: [127.0.0.1]

PLAY RECAP *********************************************************************
127.0.0.1                  : ok=6    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```
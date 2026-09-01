📋 Itinerario de "Fase 1: Auditoría y Resiliencia"

## Caso 3: "La prueba de la resiliencia" (Destrucción total)
- Este es el "bautismo de fuego" del DevOps.
- Reto: Vamos a convertir tu Vagrantfile en un script de Infraestructura como Código perfecto. Tras ejecutar vagrant destroy, al hacer vagrant up, el servidor debe configurarse solo (Firewall, Usuarios, Llaves SSH, Nginx, Fail2ban, Logrotate) en menos de 3 minutos. Si falta un paso manual, el despliegue falla.
- Qué aprenderás: IaC (Infrastructure as Code) real y consistencia de entornos.

### MODIFICACIÓN VAGRANT FILE
+ Añadimos:
```
config.vm.provision "shell", inline: <<-SHELL
    # --- PARTE 1: NGINX (Lo que ya tenías) ---
    apt-get update -y
    apt-get install -y nginx
    systemctl start nginx
    # Copiamos tu archivo de la carpeta compartida al servidor web
    cp /vagrant/index.html /var/www/html/index.html

    # --- PARTE 2: SEGURIDAD (Caso 1: Fail2ban) ---
    apt-get install -y fail2ban
    cat <<EOF > /etc/fail2ban/jail.local
[sshd]
enabled = true
maxretry = 3
bantime = 1h
EOF
    systemctl restart fail2ban

    # --- PARTE 3: LIMPIEZA (Caso 2: Logrotate) ---
    cat <<EOF > /etc/logrotate.d/fake_log
/var/log/fake_massive_log.log {
    su root syslog
    rotate 3
    size 1G
    compress
    missingok
    notifempty
}
EOF

    # --- PARTE 4: FIREWALL (Seguridad extra) ---
    ufw allow 22/tcp
    ufw allow 80/tcp
    ufw --force enable

    echo "¡Servidor INDESTRUCTIBLE configurado con éxito!"
  SHELL
```

### 🛡️ Desglose del Script de Aprovisionamiento
1. La técnica cat <<EOF (Redirección de bloque)
Esta es la parte que más te ha chocado. Se llama Heredoc (Here Document).  
cat: Es el comando para leer o mostrar archivos.  
<<EOF: Le dice a Bash: "No busques un archivo. Lee todo lo que voy a escribir a continuación hasta que encuentres la palabra EOF (End Of File)".  
> /ruta/archivo: Todo ese bloque de texto se guardará directamente en el archivo que le indiquemos.


2. Gestión de Paquetes
apt-get update -y: Actualiza la lista de aplicaciones disponibles. La -y (yes) es vital en scripts: le dice al servidor que no te pregunte "Confirmar [S/n]", que diga que sí a todo automáticamente.  
apt-get install -y fail2ban: Descarga e instala el programa.  

3. El Firewall (UFW)
ufw: Significa Uncomplicated FireWall. Es la muralla del servidor.  
allow 22/tcp: Deja pasar el tráfico por el puerto 22 (SSH). ¡IMPORTANTE! Si activas el firewall y no pones esto, te quedarás fuera de tu propio servidor.  
allow 80/tcp: Abre la puerta para que el mundo pueda ver tu web (Nginx).  
--force enable: Enciende el muro. El --force evita que el sistema te pregunte: "¿Estás seguro? Podrías perder la conexión".

4. Configuración de Logrotate
su root syslog: (Switch User). Le dice a Logrotate: "Actúa como el usuario root y el grupo syslog". Esto soluciona el error de permisos que vimos antes.  
missingok: (Missing Okay). Si el log no existe ese día, no te quejes ni des error.  
notifempty: (Not If Empty). Si el log pesa 0 bytes, no pierdas el tiempo rotándolo.  

### Creamos de nuevo la máquina virtual
1. Borramos toda la MV `$ vagrant destroy -f`  
2. Levantamos la nueva con la nueva config del Vagrantfile `$ vagrant up`
3. Comprobamos que todo se ha creado bien:
```
$ vagrant ssh
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-172-generic x86_64)

vagrant@ubuntu-focal:~$ ls -l /etc/fail2ban/jail.local /etc/logrotate.d/fake_log
-rw-r--r-- 1 root root  48 Mar 18 23:55 /etc/fail2ban/jail.local
-rw-r--r-- 1 root root 120 Mar 18 23:55 /etc/logrotate.d/fake_log

vagrant@ubuntu-focal:~$ cat /etc/logrotate.d/fake_log
/var/log/fake_massive_log.log {
    su root syslog
    rotate 3
    size 1G
    compress
    missingok
    notifempty
}

vagrant@ubuntu-focal:~$ sudo ufw status
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
22/tcp (v6)                ALLOW       Anywhere (v6)
80/tcp (v6)                ALLOW       Anywhere (v6)
```

##### Ejemplo para entender mejor el uso de EOF
1. **Ejemplo A: Crear un mensaje de bienvenida.**  
Si quieres que cada vez que alguien entre vea un mensaje, puedes crear el archivo motd (Message Of The Day):
```
sudo cat <<EOF > /etc/motd
******************************************
* BIENVENIDO AL SERVIDOR DE MIGUEL     *
* PROHIBIDO EL PASO A INTRUSOS         *
******************************************
EOF
```

2. **Ejemplo B: Crear un script de Bash dentro de otro script**  
A veces quieres que tu servidor cree un pequeño programa de limpieza:
```
cat <<EOF > /home/vagrant/limpiar.sh
#!/bin/bash
echo "Limpiando archivos temporales..."
sudo rm -rf /tmp/*
echo "Limpieza completada."
EOF
```
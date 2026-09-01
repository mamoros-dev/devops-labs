📋 Itinerario de "Fase 1: Auditoría y Resiliencia"

## Caso 1: Defensa contra ataques (Fail2ban)
- No basta con un firewall. Los ataques de fuerza bruta al puerto 22 son constantes.
- Reto: Configurar fail2ban para monitorear logs. Si detecta N intentos fallidos, bloquea la IP del atacante mediante el Firewall automáticamente.
- Qué aprenderás: Análisis de logs (/var/log/auth.log) y automatización de la seguridad en tiempo real.

### 📋 El Escenario
+ Tu servidor 192.168.56.10 está en la red y tiene el puerto 22 (SSH) abierto. En el mundo real, en cuanto un servidor asoma la cabeza a internet, miles de bots empiezan a probar combinaciones de usuario y contraseña (admin, 1234, root...) para entrar.

+ Si un bot intenta 10,000 contraseñas por hora, tarde o temprano podría entrar. Tu misión es instalar un "portero" automático que, si ve que alguien falla 3 veces, le prohíba la entrada (banee su IP) durante una hora.

### 🛠️ Tu Hoja de Ruta (El Reto)
+ Para solucionar esto, tienes que usar una herramienta llamada Fail2Ban. Funciona leyendo los archivos de "log" (el diario donde el servidor escribe todo lo que pasa) y ejecutando reglas de Firewall al detectar ataques.

+ Pasos que debes seguir (inténtalo tú primero):  
1. Instalación: Necesitas instalar el paquete fail2ban.
2. Configuración: Fail2ban usa un archivo llamado jail.conf, pero los profesionales nunca editan ese. Crean uno llamado jail.local para sus propias reglas.  
3. La Regla de Oro: Tienes que configurar la sección [sshd] para que:
```
enabled = true
maxretry = 3 (A los 3 fallos, fuera).
bantime = 1h (Tiempo de baneo).
Verificación: Tienes que comprobar que el servicio está corriendo y ver la "lista negra".
```

### 👨‍🏫 Pistas de "Senior" para ayudarte:
+ ¿Dónde están los logs de intentos de entrada? Mira en /var/log/auth.log. Ahí verás cada vez que alguien intenta hacer SSH.

+ Comandos útiles:
```
sudo apt install ... (ya sabes cuál).
sudo systemctl status fail2ban (para ver si vive).
fail2ban-client status sshd (este es el comando "mágico" para ver a quién has baneado).
```
1. Lo instalo `vagrant@ubuntu-focal:~$ sudo apt install fail2ban`  
2. Compruebo el estado del servicio `vagrant@ubuntu-focal:~$ systemctl status fail2ban`
3. He instalado el paquete locate para ver donde está el fichero de configuración:
```
vagrant@ubuntu-focal:~$ locate jail.conf
/etc/fail2ban/jail.conf --> este es
/usr/lib/python3/dist-packages/fail2ban/tests/config/jail.conf
/usr/share/man/man5/jail.conf.5.gz
```
4. He creado un fichero de pruebas `vagrant@ubuntu-focal:~$ sudo vi /etc/fail2ban/jail_miguel.conf`:  
```
# SECCION PARA INDICAR QUE POR SSH SE BANEE POR 3 INTENTOS ERRONEOS Y UNA HORA DE BANEO
[sshd]
enabled = true
port    = ssh
filter  = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime  = 1h
findtime = 10m
```
> filter = sshd: Es el "diccionario". Le dice: "Busca fallos usando las reglas predefinidas para SSH".  
> logpath = ...: Es la "dirección del diario". Le dice exactamente qué archivo leer.  
> findtime = 10m: Es la "ventana de tiempo". Si fallas 3 veces en un mes, no pasa nada. Pero si fallas 3 veces en 10 minutos, ¡Baneado!  

5. He reiniciado el servicio `vagrant@ubuntu-focal:~$ sudo systemctl restart fail2ban`  
6. Pruebo con +4 intentos entrar por ssh erroneamente:
```
PS C:\WINDOWS\system32> ssh -o PubkeyAuthentication=no vagrant@miguel-dev.local
vagrant@miguel-dev.local's password:
Permission denied, please try again.
vagrant@miguel-dev.local's password:
Permission denied, please try again.
vagrant@miguel-dev.local's password:
vagrant@miguel-dev.local: Permission denied (publickey,password).
PS C:\WINDOWS\system32>
```
> Como tenía las llaves publicas para provocar que me pida el password, en el fichero `/etc/ssh/sshd_config` configuré el `PasswordAuthentication yes`  

7. Resultado:
```
PS C:\WINDOWS\system32> ssh -o PubkeyAuthentication=no vagrant@miguel-dev.local
vagrant@miguel-dev.local: Permission denied (publickey).
PS C:\WINDOWS\system32> ssh -o PubkeyAuthentication=no vagrant@miguel-dev.local
vagrant@miguel-dev.local's password:
Permission denied, please try again.
vagrant@miguel-dev.local's password:
Permission denied, please try again.
vagrant@miguel-dev.local's password:
vagrant@miguel-dev.local: Permission denied (publickey,password).
PS C:\WINDOWS\system32> ssh -o PubkeyAuthentication=no vagrant@miguel-dev.local
vagrant@miguel-dev.local's password:
Permission denied, please try again.
vagrant@miguel-dev.local's password:
Permission denied, please try again.
vagrant@miguel-dev.local's password:
ssh_dispatch_run_fatal: Connection to 192.168.56.10 port 22: Connection timed out

vagrant@ubuntu-focal:~$ sudo fail2ban-client status sshd
Status for the jail: sshd
|- Filter
|  |- Currently failed: 0
|  |- Total failed:     5
|  `- File list:        /var/log/auth.log
`- Actions
   |- Currently banned: 1
   |- Total banned:     1
   `- Banned IP list:   192.168.56.1
vagrant@ubuntu-focal:~$ 
```

### RESUMEN
+ Diagnosticar un fallo de servicio (cuando pusimos maxretry = 0).  
+ Configurar seguridad reactiva (Fail2ban).  
+ Realizar un test de penetración básico (forzar el login por password para probar el baneo).  
+ Auditar el estado de la seguridad (fail2ban-client status).  




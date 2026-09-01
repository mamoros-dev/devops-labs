📋 Itinerario de "Fase 1: Auditoría y Resiliencia"

## Caso 2: Gestión de almacenamiento y Logs (Logrotate)
- Un servidor web que no gestiona sus logs termina colapsando el disco duro, y una vez lleno, el sistema operativo empieza a corromperse (no puede escribir archivos temporales).
- Reto: Crear un log de 100MB artificialmente para ver cómo el sistema gestiona el espacio. Luego, configurar logrotate para que el servidor archive y borre logs antiguos sin que tú tengas que intervenir.
- Qué aprenderás: Gestión de almacenamiento (df -h, du), particiones y mantenimiento preventivo.

### 🚨 Escenario - Caso Real 02: "El desastre del disco lleno"

+ Son las 3:00 AM. Recibes una alerta: El servidor web Nginx ha dejado de funcionar.
Entras por SSH y ves que el servicio está caído. Intentas reiniciarlo, pero falla. Miras los logs y descubres que el disco duro está al 100%. No queda ni un solo byte libre para que Nginx escriba sus archivos temporales o sus propios logs.

+ El culpable:
    - Un archivo de log (/var/log/nginx/access.log) ha crecido descontroladamente porque hay mucho tráfico o un ataque, y nadie configuró la limpieza automática.

+ Tu Misión:
    - Identificar el problema: Aprender a ver cuánto espacio queda y qué carpetas "pesan" más.
    - Solución de emergencia: Simular un archivo gigante y borrarlo de forma segura.
    - Prevención (Nivel Pro): Configurar logrotate para que los archivos de log nunca crezcan hasta llenar el disco (comprimirlos y borrarlos cada X tiempo).

### 🛠️ Paso 1: Diagnóstico de espacio
1. Entra en tu terminal de Vagrant y ejecuta estos dos comandos "sagrados" para todo SysAdmin:  
`df -h: (Disk Free - Human readable). Te dice cuánto espacio total queda en cada "disco" (partición).`
> Fíjate especialmente en la línea que monta en /.  

`du -sh /var/log/*: (Disk Usage). Te dice cuánto ocupa cada archivo o carpeta dentro de /var/log.`

2. Estado original:
```
vagrant@ubuntu-focal:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            466M     0  466M   0% /dev
tmpfs            97M 1004K   96M   2% /run
/dev/sda1        39G  1.8G   37G   5% /
tmpfs           483M     0  483M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           483M     0  483M   0% /sys/fs/cgroup
/dev/loop0       64M   64M     0 100% /snap/core20/2182
/dev/loop1       92M   92M     0 100% /snap/lxd/24061
/dev/loop2       41M   41M     0 100% /snap/snapd/20671
vagrant         476G  163G  313G  35% /vagrant
tmpfs            97M     0   97M   0% /run/user/1000
/dev/loop3       49M   49M     0 100% /snap/snapd/26382
```
> /dev/sda1 (El Disco Principal): Tienes 37GB libres (solo un 5% de uso). Es un lienzo en blanco.  
> /dev/loop (Los Snaps): Verás que están al 100%. No te asustes, es normal. Los paquetes "Snap" son de solo lectura y siempre aparecen como llenos.  
> /vagrant: Es la carpeta compartida con tu Windows. Fíjate que tiene 476GB. Es un puente directo a tu disco real.  

3. Creamos un fichero de Zeros para simular que llenamos el disco duro:
`sudo dd if=/dev/zero of=/var/log/fake_massive_log.log bs=10M count=500`  
```
vagrant@ubuntu-focal:~$ sudo dd if=/dev/zero of=/var/log/fake_massive_log.log bs=10M count=500
500+0 records in
500+0 records out
5242880000 bytes (5.2 GB, 4.9 GiB) copied, 10.1123 s, 518 MB/s
vagrant@ubuntu-focal:~$ ls -lh /var/log/fake_massive_log.log
-rw-r--r-- 1 root root 4.9G Mar 18 23:07 /var/log/fake_massive_log.log
```
> 10MB x 500 veces = 5000MB ≈ 5GB

4. Ha aumentado el espacio usado:
```
vagrant@ubuntu-focal:~$ df -h
Filesystem      Size  Used Avail Use% Mounted on
udev            466M     0  466M   0% /dev
tmpfs            97M 1004K   96M   2% /run
/dev/sda1        39G  6.7G   33G  18% /
tmpfs           483M     0  483M   0% /dev/shm
tmpfs           5.0M     0  5.0M   0% /run/lock
tmpfs           483M     0  483M   0% /sys/fs/cgroup
/dev/loop0       64M   64M     0 100% /snap/core20/2182
/dev/loop1       92M   92M     0 100% /snap/lxd/24061
/dev/loop2       41M   41M     0 100% /snap/snapd/20671
vagrant         476G  163G  313G  35% /vagrant
tmpfs            97M     0   97M   0% /run/user/1000
/dev/loop3       49M   49M     0 100% /snap/snapd/26382
```

5. Logrotate es una herramienta del sistema diseñada para administrar la creación descontrolada de archivos de registro (logs). Su función principal es rotar, comprimir y eliminar logs automáticamente para evitar que el disco duro se llene. Creamos un arhivo para que haga la función que nos interesa:
`sudo vi /etc/logrotate.d/fake_log`
```
/var/log/fake_massive_log.log {
    rotate 3
    nocompress
    missingok
    notifempty
    size 1G
}
```
> Le estamos diciendo: "Si este archivo llega a 1GB, rótalo y solo guarda 3 copias".  
> daily: Intenta rotar el archivo cada día.  
> rotate 3: Solo guarda los últimos 3 archivos antiguos. El cuarto más viejo se borra (¡adiós problema de espacio!).  
> compress: Comprime los archivos rotados en .gz (un log de 5GB de ceros comprimido ocupará apenas unos KBs).  
> missingok: Si el archivo no existe, no lances un error.  
> notifempty: No rotes el archivo si está vacío.  

+ Forzamos la rotación y vemos lo que hay:
sudo logrotate -f /etc/logrotate.d/fake_log

+ Error:
```vagrant@ubuntu-focal:~$ sudo logrotate -f /etc/logrotate.d/fake_log
error: skipping "/var/log/fake_massive_log.log" because parent directory has insecure permissions (It's world writable or writable by group which is not "root") Set "su" directive in config file to tell logrotate which user/group should be used for rotation.
```
> Linux es muy desconfiado. logrotate se ejecuta con permisos de root (superusuario). Si la carpeta donde está el log (/var/log) o el archivo mismo tienen permisos que permiten que "cualquiera" escriba en ellos, logrotate se niega a trabajar.  
> Tenemos que decirle a logrotate: "Oye, aunque el archivo parezca inseguro, usa al usuario root y al grupo syslog para hacer la rotación".  

+ Correción:
```
/var/log/fake_massive_log.log {
    su root syslog
    rotate 3
    size 1G
    nocompress
    missingok
    notifempty
}
```

+ Resultado:  
```
vagrant@ubuntu-focal:~$ sudo logrotate -f /etc/logrotate.d/fake_log
vagrant@ubuntu-focal:~$ ls -lh /var/log/fake_massive_log*
-rw-r--r-- 1 root root 4.9G Mar 18 23:07 /var/log/fake_massive_log.log.1
```
> Esto hace limpiar la ruta donde se acumulaba el archivo y lo rota a otro fichero

+ Si quisieramos liberar espacio, podríamos usar la opción COMPRESS y entonces el fichero lo rotaría comprimiendo y liberando espacio en disco: 
```
vagrant@ubuntu-focal:~$ sudo dd if=/dev/zero of=/var/log/fake_massive_log.log bs=10M count=500
500+0 records in
500+0 records out
5242880000 bytes (5.2 GB, 4.9 GiB) copied, 9.48329 s, 553 MB/s
vagrant@ubuntu-focal:~$ sudo vi /etc/logrotate.d/fake_log
vagrant@ubuntu-focal:~$ cat /etc/logrotate.d/fake_log
/var/log/fake_massive_log.log {
    su root syslog
    rotate 3
    size 1G
    compress
    missingok
    notifempty
}
vagrant@ubuntu-focal:~$ sudo logrotate -f /etc/logrotate.d/fake_log
vagrant@ubuntu-focal:~$ ls -lh /var/log/fake_massive_log*
-rw-r--r-- 1 root root 4.9M Mar 18 23:25 /var/log/fake_massive_log.log.1.gz
-rw-r--r-- 1 root root 4.9G Mar 18 23:07 /var/log/fake_massive_log.log.2
```

### RESUMEN 🔍 Analizando tu "Milagro de Espacio"
+ fake_massive_log.log.2: Pesa 4.9G. Es el archivo original que creamos. Como no estaba comprimido en la rotación anterior, se ha quedado con su tamaño real al renombrarse.  
+ fake_massive_log.log.1.gz: ¡Pesa solo 4.9M!
> ¿Qué ha pasado aquí? Has activado compress. El ahorro: Has pasado de 5000 MB a menos de 5 MB. Has recuperado el 99.9% del espacio que ocupaba ese log sin borrar la información.

+ **COMPARATIVA**:
- Caso A: Rotación Simple:
    + Solo renombra el archivo (.log → .log.1).
    + Sigue ocupado. El problema de "Disco Lleno" persiste hasta que se borre el archivo.
    + Casi nunca se usa solo, salvo para logs muy pequeños.
    + Verás archivos grandes con números al final.

- Caso B: Rotación con Compresión
    + Renombra y comprime (.log → .log.1.gz).
    + Se libera casi todo. El disco vuelve a respirar al instante.
    + Es el estándar profesional. Permite guardar meses de historial sin llenar el servidor.
    + Verás archivos con extensión .gz (icono de paquete comprimido).

+ **APRENDIDO**:
 - Cómo evitarías que un servidor se caiga por falta de espacio en los logs?", tu respuesta ahora es de experto:  
    > "Configuraría una política de Logrotate en /etc/logrotate.d/ con la directiva compress y un límite de rotate adecuado. Además, en casos de archivos conflictivos, usaría la directiva su para asegurar que los permisos no bloqueen la rotación".